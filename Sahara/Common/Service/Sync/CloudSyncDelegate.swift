//
//  CloudSyncDelegate.swift
//  Sahara
//

import CloudKit
import OSLog
import RealmSwift
import RxSwift

final class CloudSyncDelegate: NSObject, CKSyncEngineDelegate, @unchecked Sendable {
    private let logger = Logger.sync

    private let realmService: RealmServiceProtocol
    private let imageFileService: ImageFileServiceProtocol
    private let stateSerializer: CloudSyncStateSerializer
    private let disposeBag = DisposeBag()

    private let cacheQueue = DispatchQueue(label: "com.miya.Sahara.serverRecordCache")
    private var serverRecordCache: [CKRecord.ID: CKRecord] = [:]

    weak var syncService: CloudSyncService?

    init(
        realmService: RealmServiceProtocol,
        imageFileService: ImageFileServiceProtocol,
        stateSerializer: CloudSyncStateSerializer
    ) {
        self.realmService = realmService
        self.imageFileService = imageFileService
        self.stateSerializer = stateSerializer
    }

    // MARK: - CKSyncEngineDelegate

    func handleEvent(_ event: CKSyncEngine.Event, syncEngine: CKSyncEngine) {
        switch event {
        case .stateUpdate(let stateUpdate):
            stateSerializer.save(stateUpdate.stateSerialization)

        case .accountChange(let accountChange):
            handleAccountChange(accountChange)

        case .fetchedDatabaseChanges(let fetchedChanges):
            handleFetchedDatabaseChanges(fetchedChanges)

        case .fetchedRecordZoneChanges(let fetchedChanges):
            handleFetchedRecordZoneChanges(fetchedChanges)

        case .sentRecordZoneChanges(let sentChanges):
            handleSentRecordZoneChanges(sentChanges)

        case .willFetchChanges:
            logger.info("Will fetch changes from iCloud")
            syncService?.updateSyncStatus(.syncing)

        case .didFetchChanges:
            logger.info("Did fetch changes from iCloud")
            syncService?.updateSyncStatus(.upToDate)

        case .willSendChanges:
            logger.info("Will send changes to iCloud")
            syncService?.updateSyncStatus(.syncing)

        case .didSendChanges:
            logger.info("Did send changes to iCloud")
            syncService?.updateSyncStatus(.upToDate)

        case .sentDatabaseChanges,
             .willFetchRecordZoneChanges,
             .didFetchRecordZoneChanges:
            break

        @unknown default:
            logger.notice("Unknown CKSyncEngine event received")
        }
    }

    func nextRecordZoneChangeBatch(
        _ context: CKSyncEngine.SendChangesContext,
        syncEngine: CKSyncEngine
    ) async -> CKSyncEngine.RecordZoneChangeBatch? {
        let scope = context.options.scope
        let pendingChanges = syncEngine.state.pendingRecordZoneChanges
            .filter { scope.contains($0) }

        return await CKSyncEngine.RecordZoneChangeBatch(
            pendingChanges: pendingChanges
        ) { recordID in
            self.buildRecord(for: recordID)
        }
    }

    // MARK: - Event Handlers

    private func handleAccountChange(_ event: CKSyncEngine.Event.AccountChange) {
        switch event.changeType {
        case .signIn:
            logger.info("iCloud account signed in")
        case .signOut:
            logger.info("iCloud account signed out")
            syncService?.updateSyncStatus(.accountUnavailable)
        case .switchAccounts:
            logger.info("iCloud account switched — restarting sync")
            stateSerializer.clear()
            syncService?.stopSync()
            syncService?.startSync()
            syncService?.triggerFullSync()
        @unknown default:
            break
        }
    }

    private func handleFetchedDatabaseChanges(
        _ event: CKSyncEngine.Event.FetchedDatabaseChanges
    ) {
        for deletion in event.deletions {
            if deletion.zoneID == CloudSyncRecordMapper.zoneID {
                logger.warning("SaharaZone deleted from iCloud — recreating zone and triggering full sync")
                syncService?.ensureZoneExists()
                syncService?.triggerFullSync()
            }
        }
    }

    private func handleFetchedRecordZoneChanges(
        _ event: CKSyncEngine.Event.FetchedRecordZoneChanges
    ) {
        var hasChanges = false

        for modification in event.modifications {
            cacheQueue.sync { serverRecordCache[modification.record.recordID] = modification.record }
            applyRemoteModification(modification.record)
            hasChanges = true
        }

        for deletion in event.deletions {
            applyRemoteDeletion(deletion.recordID)
            hasChanges = true
        }

        if hasChanges {
            WidgetDataService.shared.refreshWidgetData()
        }
    }

    private func handleSentRecordZoneChanges(
        _ event: CKSyncEngine.Event.SentRecordZoneChanges
    ) {
        for savedRecord in event.savedRecords {
            cacheQueue.sync { serverRecordCache[savedRecord.recordID] = savedRecord }
        }

        for failure in event.failedRecordSaves {
            let errorCode = failure.error.code
            switch errorCode {
            case .serverRecordChanged:
                if let serverRecord = failure.error.serverRecord {
                    cacheQueue.sync { serverRecordCache[serverRecord.recordID] = serverRecord }
                    applyRemoteModification(serverRecord)
                }
            case .zoneNotFound:
                syncService?.ensureZoneExists()
            case .quotaExceeded:
                logger.error("iCloud storage quota exceeded")
                syncService?.updateSyncStatus(
                    .error(NSLocalizedString("sync.error_quota", comment: ""))
                )
            default:
                logger.error("Record save failed [\(errorCode.rawValue)]: \(failure.error.localizedDescription)")
            }
        }
    }

    // MARK: - Remote Modification

    private func applyRemoteModification(_ record: CKRecord) {
        guard record.recordType == CloudSyncRecordMapper.recordType else { return }
        guard let cardId = CloudSyncRecordMapper.cardId(from: record.recordID) else {
            logger.error("Invalid record name: \(record.recordID.recordName)")
            return
        }

        let cardIdString = cardId.stringValue
        syncService?.addRemoteModifiedId(cardIdString)

        var didApply = false
        var imageChanged = false

        realmService.update { realm in
            let card: Card
            if let existing = realm.object(ofType: Card.self, forPrimaryKey: cardId) {
                let remoteModified = record[CloudSyncRecordMapper.RecordField.modifiedDate] as? Date
                    ?? record.modificationDate
                    ?? Date.distantPast
                let localModified = existing.modifiedDate ?? existing.createdDate

                if remoteModified <= localModified {
                    return
                }
                card = existing
            } else {
                card = Card()
                card.id = cardId
                realm.add(card)
            }

            CloudSyncRecordMapper.applyRecord(record, to: card)

            if let asset = record[CloudSyncRecordMapper.RecordField.imageAsset] as? CKAsset,
               asset.fileURL != nil {
                let format = record[CloudSyncRecordMapper.RecordField.imageFormat] as? String
                if let fileName = CloudSyncImageHandler.saveAssetToDisk(
                    asset,
                    cardId: cardId,
                    format: format,
                    imageFileService: self.imageFileService
                ) {
                    card.imagePath = fileName
                    card.editedImageData = nil
                    imageChanged = true
                }
            }

            didApply = true
        }
        .subscribe(
            onNext: { [weak self] in
                guard let self else { return }
                if !didApply {
                    _ = self.syncService?.removeRemoteModifiedId(cardIdString)
                }
                if imageChanged {
                    ThumbnailCache.shared.invalidate(for: cardId)
                }
            },
            onError: { [weak self, logger] error in
                _ = self?.syncService?.removeRemoteModifiedId(cardIdString)
                logger.error("Failed to apply remote modification for \(cardIdString): \(error.localizedDescription)")
            }
        )
        .disposed(by: disposeBag)
    }

    private func applyRemoteDeletion(_ recordID: CKRecord.ID) {
        guard let cardId = CloudSyncRecordMapper.cardId(from: recordID) else { return }

        var imagePath: String?
        realmService.update { realm in
            guard let card = realm.object(ofType: Card.self, forPrimaryKey: cardId) else { return }
            imagePath = card.imagePath
            realm.delete(card)
        }
        .subscribe(
            onNext: { [imageFileService] in
                if let imagePath { imageFileService.deleteImageFile(at: imagePath) }
            },
            onError: { [logger] error in
                logger.error("Failed to apply remote deletion for \(cardId.stringValue): \(error.localizedDescription)")
            }
        )
        .disposed(by: disposeBag)

        ThumbnailCache.shared.invalidate(for: cardId)
    }

    // MARK: - Record Building
    //
    // CKSyncEngine이 nextRecordZoneChangeBatch를 백그라운드 스레드에서 호출한다.
    // Realm 인스턴스는 스레드 제한적이므로 메인 스레드 인스턴스를 재사용하지 않고
    // 여기서 별도 인스턴스를 생성한다.

    private func buildRecord(for recordID: CKRecord.ID) -> CKRecord? {
        guard let cardId = CloudSyncRecordMapper.cardId(from: recordID) else { return nil }
        guard let realm = try? Realm(configuration: realmService.createConfiguration()) else { return nil }
        guard let card = realm.object(ofType: Card.self, forPrimaryKey: cardId) else { return nil }

        let record = cacheQueue.sync { serverRecordCache[recordID] }
            ?? CKRecord(
                recordType: CloudSyncRecordMapper.recordType,
                recordID: recordID
            )

        let imageAsset = CloudSyncImageHandler.createAsset(
            for: card,
            imageFileService: imageFileService
        )
        CloudSyncRecordMapper.populateRecord(record, from: card, imageAsset: imageAsset)

        return record
    }

}
