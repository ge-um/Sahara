//
//  CloudSyncService.swift
//  Sahara
//

import CloudKit
import Foundation
import OSLog
import RealmSwift
import UIKit

final class CloudSyncService: CloudSyncServiceProtocol {
    static let containerIdentifier = "iCloud.\(Bundle.main.bundleIdentifier ?? "com.miya.Sahara")"

    static var current: CloudSyncService? {
        (UIApplication.shared.delegate as? AppDelegate)?.cloudSyncService
    }

    private enum Keys {
        static let enabled = "cloudSyncEnabled"
        static let lastDate = "cloudSyncLastDate"
    }

    private let logger = Logger.sync

    private var syncEngine: CKSyncEngine?
    private var syncDelegate: CloudSyncDelegate?
    private var realmNotificationToken: NotificationToken?

    private let realmService: RealmServiceProtocol
    private let imageFileService: ImageFileServiceProtocol
    private let stateSerializer: CloudSyncStateSerializer

    private let syncQueue = DispatchQueue(label: "com.miya.Sahara.cloudSync")

    private var remoteModifiedIds = Set<String>()

    func addRemoteModifiedId(_ id: String) {
        syncQueue.sync { _ = remoteModifiedIds.insert(id) }
    }

    /// Returns `true` if the ID was present (i.e. this was an echo-back from a remote change).
    func removeRemoteModifiedId(_ id: String) -> Bool {
        syncQueue.sync { remoteModifiedIds.remove(id) != nil }
    }

    private(set) var status: CloudSyncStatus = .disabled {
        didSet {
            guard status != oldValue else { return }
            NotificationCenter.default.post(
                name: .cloudSyncStatusChanged,
                object: self,
                userInfo: ["status": status]
            )
        }
    }

    var isEnabled: Bool {
        UserDefaults.standard.bool(forKey: Keys.enabled)
    }

    var isSyncing: Bool {
        status == .syncing
    }

    var lastSyncDate: Date? {
        get { UserDefaults.standard.object(forKey: Keys.lastDate) as? Date }
        set { UserDefaults.standard.set(newValue, forKey: Keys.lastDate) }
    }

    init(
        realmService: RealmServiceProtocol,
        imageFileService: ImageFileServiceProtocol,
        stateSerializer: CloudSyncStateSerializer = CloudSyncStateSerializer()
    ) {
        self.realmService = realmService
        self.imageFileService = imageFileService
        self.stateSerializer = stateSerializer
    }

    deinit {
        realmNotificationToken?.invalidate()
    }

    // MARK: - CloudSyncServiceProtocol

    func startSync() {
        guard syncEngine == nil else { return }

        let container = CKContainer(identifier: Self.containerIdentifier)
        let database = container.privateCloudDatabase

        let delegate = CloudSyncDelegate(
            realmService: realmService,
            imageFileService: imageFileService,
            stateSerializer: stateSerializer
        )
        delegate.syncService = self
        self.syncDelegate = delegate

        let stateSerialization = stateSerializer.load()

        let configuration = CKSyncEngine.Configuration(
            database: database,
            stateSerialization: stateSerialization,
            delegate: delegate
        )

        let engine = CKSyncEngine(configuration)
        self.syncEngine = engine

        UserDefaults.standard.set(true, forKey: Keys.enabled)
        updateSyncStatus(.upToDate)

        ensureZoneExists()
        observeRealmChanges()

        logger.info("CloudSyncService started")
    }

    func stopSync() {
        realmNotificationToken?.invalidate()
        realmNotificationToken = nil

        syncEngine = nil
        syncDelegate = nil

        stateSerializer.clear()
        UserDefaults.standard.set(false, forKey: Keys.enabled)
        updateSyncStatus(.disabled)

        logger.info("CloudSyncService stopped")
    }

    func notifyChange(recordID: String, type: CloudSyncChangeType) {
        guard let engine = syncEngine,
              let objectId = try? ObjectId(string: recordID) else { return }

        let ckRecordID = CloudSyncRecordMapper.recordID(for: objectId)

        syncQueue.async {
            switch type {
            case .save:
                engine.state.add(pendingRecordZoneChanges: [.saveRecord(ckRecordID)])
            case .delete:
                engine.state.add(pendingRecordZoneChanges: [.deleteRecord(ckRecordID)])
            }
        }
    }

    func triggerFullSync() {
        guard let engine = syncEngine else { return }

        try? realmService.migrateAllLegacyImagesToDisk(imageFileService: imageFileService)

        let allCards = realmService.fetch(Card.self)
        let pendingChanges: [CKSyncEngine.PendingRecordZoneChange] = allCards.map { card in
            .saveRecord(CloudSyncRecordMapper.recordID(for: card.id))
        }

        syncQueue.async {
            engine.state.add(pendingRecordZoneChanges: pendingChanges)
        }

        logger.info("Triggered full sync for \(allCards.count) cards")
    }

    func checkAccountStatus(completion: @escaping (Bool) -> Void) {
        let container = CKContainer(identifier: Self.containerIdentifier)
        container.accountStatus { [logger] status, error in
            DispatchQueue.main.async {
                if let error {
                    logger.error("Account status check failed: \(error.localizedDescription)")
                    completion(false)
                    return
                }
                completion(status == .available)
            }
        }
    }

    // MARK: - Internal

    func updateSyncStatus(_ newStatus: CloudSyncStatus) {
        DispatchQueue.main.async {
            self.status = newStatus
            if newStatus == .upToDate {
                self.lastSyncDate = Date()
            }
        }
    }

    func ensureZoneExists() {
        guard let engine = syncEngine else { return }
        let zone = CKRecordZone(zoneID: CloudSyncRecordMapper.zoneID)
        engine.state.add(pendingDatabaseChanges: [.saveZone(zone)])
    }

    // MARK: - Realm Observation (catches update() calls for Card modifications)
    //
    // 에코백 방지는 addRemoteModifiedId()가 Realm observer 발동 전에 호출되어야 작동한다.
    // RealmService.update()가 동기적으로 write하기 때문에 (같은 스레드에서 Observable 방출),
    // observer 알림은 ID가 이미 등록된 후에 도착한다.
    // update()가 비동기로 변경되면 observer가 먼저 발동하여
    // 원격 변경을 다시 iCloud로 업로드하는 무한루프가 발생할 수 있다.

    private func observeRealmChanges() {
        guard let realm = try? Realm(configuration: realmService.createConfiguration()) else {
            logger.error("Failed to create Realm for sync observation")
            return
        }

        let results = realm.objects(Card.self)
        realmNotificationToken = results.observe { [weak self] changes in
            guard let self else { return }

            switch changes {
            case .update(let collection, let deletions, let insertions, let modifications):
                for index in insertions {
                    let card = collection[index]
                    let cardId = card.id.stringValue
                    if !self.removeRemoteModifiedId(cardId) {
                        self.notifyChange(recordID: cardId, type: .save)
                    }
                }
                for index in modifications {
                    let card = collection[index]
                    let cardId = card.id.stringValue
                    if self.removeRemoteModifiedId(cardId) {
                        self.logger.debug("Skipped echo-back for \(cardId)")
                    } else {
                        self.notifyChange(recordID: cardId, type: .save)
                    }
                }
                if !deletions.isEmpty {
                    self.logger.warning("Realm observer: \(deletions.count) deletion(s) without explicit sync")
                }
            case .initial, .error:
                break
            }
        }
    }

    // MARK: - Manual Fetch

    func fetchChangesIfNeeded() {
        guard let engine = syncEngine else { return }
        Task {
            try? await engine.fetchChanges()
        }
    }

    // MARK: - Backup Integration

    func stopSyncForBackupRestore() {
        realmNotificationToken?.invalidate()
        realmNotificationToken = nil
        syncEngine = nil
        syncDelegate = nil
        stateSerializer.clear()
        logger.info("Sync stopped for backup restore — state cleared")
    }

    func restartSyncAfterBackupRestore() {
        startSync()
        triggerFullSync()
        logger.info("Sync restarted after backup restore — full sync triggered")
    }
}

// MARK: - State Serialization

final class CloudSyncStateSerializer {
    private let fileURL: URL

    private let logger = Logger.syncState

    init() {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )[0]
        self.fileURL = appSupport.appendingPathComponent("CKSyncEngineState.data")
    }

    func save(_ serialization: CKSyncEngine.State.Serialization) {
        do {
            let data = try JSONEncoder().encode(serialization)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            logger.error("Failed to save sync state: \(error.localizedDescription)")
        }
    }

    func load() -> CKSyncEngine.State.Serialization? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return try? JSONDecoder().decode(
            CKSyncEngine.State.Serialization.self,
            from: data
        )
    }

    func clear() {
        try? FileManager.default.removeItem(at: fileURL)
    }
}
