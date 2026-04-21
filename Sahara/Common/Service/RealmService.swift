//
//  RealmService.swift
//  Sahara
//
//  Created by 금가경 on 9/26/25.
//

import Foundation
import OSLog
import RealmSwift
import RxSwift

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Sahara", category: "RealmMigration")

enum DatePeriod {
    case day(Date)
    case month(Date)
}

protocol RealmServiceProtocol {
    func add<T: Object>(_ object: T) -> Observable<Void>
    func fetch<T: Object>(_ type: T.Type, filter: String?, sortKey: String?, ascending: Bool) -> [T]
    func fetchObject<T: Object>(_ type: T.Type, forPrimaryKey key: Any) -> T?
    func delete<T: Object>(_ object: T) -> Observable<Void>
    func delete<T: Object>(_ type: T.Type, forPrimaryKey key: Any) -> Observable<Void>
    func update(_ block: @escaping (Realm) -> Void) -> Observable<Void>
    func isEmpty<T: Object>(_ type: T.Type) -> Bool
    func fetchCards(for period: DatePeriod) -> [Card]
    func observeIsEmpty<T: Object>(_ type: T.Type) -> Observable<Bool>
    func observeCards(for period: DatePeriod) -> Observable<[CardCalendarItemDTO]>
    func observeAllCards() -> Observable<[Card]>
    func observeCards(withIds ids: [ObjectId]) -> Observable<[CardListItemDTO]>
    func observeCards(inFolder folderName: String?) -> Observable<[CardListItemDTO]>
    func fetchImageData(for cardId: ObjectId) -> Data?
    func deleteCard(forPrimaryKey key: ObjectId) -> Observable<Void>
    func createConfiguration() -> Realm.Configuration
    func migrateAllLegacyImagesToDisk(imageFileService: ImageFileServiceProtocol) throws
    func allImagePaths() -> Set<String>
}

extension RealmServiceProtocol {
    func fetch<T: Object>(_ type: T.Type) -> [T] {
        return fetch(type, filter: nil, sortKey: nil, ascending: true)
    }
}

final class RealmService: RealmServiceProtocol {
    static let shared = RealmService()

    private let configuration: Realm.Configuration
    weak var syncService: CloudSyncServiceProtocol?

    static let currentSchemaVersion: UInt64 = 3

    init(configuration: Realm.Configuration = .defaultConfiguration) {
        self.configuration = configuration
    }

    static var realmFileURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return appSupport.appendingPathComponent("default.realm")
    }

    static func migrateRealmFileIfNeeded(
        documentsDir: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0],
        appSupportDir: URL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
    ) {
        let fm = FileManager.default
        let oldURL = documentsDir.appendingPathComponent("default.realm")
        let newURL = appSupportDir.appendingPathComponent("default.realm")

        guard fm.fileExists(atPath: oldURL.path) else { return }

        try? fm.createDirectory(at: appSupportDir, withIntermediateDirectories: true)

        if fm.fileExists(atPath: newURL.path) {
            try? fm.removeItem(at: oldURL)
            cleanupAuxiliaryFiles(at: documentsDir)
            logger.notice("Realm file already at new location — removed old file from Documents/")
            return
        }

        do {
            try fm.moveItem(at: oldURL, to: newURL)
            cleanupAuxiliaryFiles(at: documentsDir)
            logger.notice("Realm file migrated from Documents/ to Application Support/")
        } catch {
            logger.error("Realm file migration failed: \(error.localizedDescription)")
        }
    }

    static func resolveRealmFileURL(
        documentsDir: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0],
        appSupportDir: URL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
    ) -> URL {
        let fm = FileManager.default
        let appSupportURL = appSupportDir.appendingPathComponent("default.realm")
        let documentsURL = documentsDir.appendingPathComponent("default.realm")

        if fm.fileExists(atPath: appSupportURL.path) {
            return appSupportURL
        }
        if fm.fileExists(atPath: documentsURL.path) {
            return documentsURL
        }
        return appSupportURL
    }

    private static func cleanupAuxiliaryFiles(at directory: URL) {
        let fm = FileManager.default
        let auxiliaryExtensions = ["lock", "note", "management"]
        for ext in auxiliaryExtensions {
            let url = directory.appendingPathComponent("default.\(ext)")
            try? fm.removeItem(at: url)
        }
    }

    func createConfiguration() -> Realm.Configuration {
        Self.createConfiguration()
    }

    static func createConfiguration(schemaVersion: UInt64 = currentSchemaVersion, migrationBlock: MigrationBlock? = nil) -> Realm.Configuration {
        var config = Realm.Configuration()
        config.fileURL = resolveRealmFileURL()
        config.schemaVersion = schemaVersion
        config.migrationBlock = migrationBlock ?? defaultMigrationBlock
        config.objectTypes = [Card.self, Sticker.self]
        return config
    }

    static let defaultMigrationBlock: MigrationBlock = { migration, oldSchemaVersion in
        if oldSchemaVersion < 1 {
            migration.enumerateObjects(ofType: "Card") { oldObject, newObject in
                if let createdDate = oldObject?["createdDate"] as? Date {
                    newObject?["date"] = createdDate
                }
            }
        }

        if oldSchemaVersion < 2 {
            // v1.4.1 → v1.5.0 스키마 변경 대응
            // Card: imageFormat(String?), drawingData(Data?) 추가 → Realm이 자동으로 nil 할당
            // Card: stickers(List<Sticker>) 제거 → Realm이 자동으로 컬럼 삭제
            // Sticker: localFilePath(String?), isAnimated(Bool) 추가 → Realm이 자동 처리
        }

        if oldSchemaVersion < 3 {
            // v1.6.1 → v2.0.0 스키마 변경 대응
            // Card: imagePath(String?) 추가 → Realm이 자동으로 nil 할당
            // Card: editedImageData(Data → Data?) 변경 → Realm이 자동으로 optional 전환
        }
    }

    static func validateRealm(configuration: Realm.Configuration = .defaultConfiguration) -> Error? {
        do {
            _ = try Realm(configuration: configuration)
            return nil
        } catch {
            return error
        }
    }

    private func getRealm() throws -> Realm {
        return try Realm(configuration: configuration)
    }

    func add<T: Object>(_ object: T) -> Observable<Void> {
        return Observable.create { observer in
            do {
                let realm = try self.getRealm()
                try realm.write {
                    realm.add(object)
                }
                if let card = object as? Card {
                    self.syncService?.notifyChange(recordID: card.id.stringValue, type: .save)
                }
                observer.onNext(())
                observer.onCompleted()
            } catch {
                observer.onError(error)
            }
            return Disposables.create()
        }
    }

    func fetch<T: Object>(_ type: T.Type, filter: String? = nil, sortKey: String? = nil, ascending: Bool = true) -> [T] {
        guard let realm = try? getRealm() else { return [] }
        var results = realm.objects(type)

        if let filter = filter {
            results = results.filter(filter)
        }

        if let sortKey = sortKey {
            results = results.sorted(byKeyPath: sortKey, ascending: ascending)
        }

        return Array(results)
    }

    func fetchObject<T: Object>(_ type: T.Type, forPrimaryKey key: Any) -> T? {
        guard let realm = try? getRealm() else { return nil }
        return realm.object(ofType: type, forPrimaryKey: key)
    }

    func delete<T: Object>(_ object: T) -> Observable<Void> {
        return Observable.create { observer in
            do {
                let realm = try self.getRealm()
                try realm.write {
                    realm.delete(object)
                }
                observer.onNext(())
                observer.onCompleted()
            } catch {
                observer.onError(error)
            }
            return Disposables.create()
        }
    }

    func delete<T: Object>(_ type: T.Type, forPrimaryKey key: Any) -> Observable<Void> {
        return Observable.create { observer in
            do {
                let realm = try self.getRealm()
                guard let object = realm.object(ofType: type, forPrimaryKey: key) else {
                    observer.onError(RealmError.objectNotFound)
                    return Disposables.create()
                }
                try realm.write {
                    realm.delete(object)
                }
                observer.onNext(())
                observer.onCompleted()
            } catch {
                observer.onError(error)
            }
            return Disposables.create()
        }
    }

    func update(_ block: @escaping (Realm) -> Void) -> Observable<Void> {
        return Observable.create { observer in
            do {
                let realm = try self.getRealm()
                try realm.write {
                    block(realm)
                }
                observer.onNext(())
                observer.onCompleted()
            } catch {
                observer.onError(error)
            }
            return Disposables.create()
        }
    }

    func isEmpty<T: Object>(_ type: T.Type) -> Bool {
        guard let realm = try? getRealm() else { return true }
        return realm.objects(type).isEmpty
    }

    func fetchCards(for period: DatePeriod) -> [Card] {
        let calendar = Calendar.current
        let startDate: Date
        let endDate: Date

        switch period {
        case .day(let date):
            startDate = calendar.startOfDay(for: date)
            guard let end = calendar.date(byAdding: .day, value: 1, to: startDate) else {
                return []
            }
            endDate = end

        case .month(let date):
            guard let start = calendar.date(from: calendar.dateComponents([.year, .month], from: date)),
                  let end = calendar.date(byAdding: .month, value: 1, to: start) else {
                return []
            }
            startDate = start
            endDate = end
        }

        guard let realm = try? getRealm() else { return [] }
        let results = realm.objects(Card.self)
            .filter("date >= %@ AND date < %@", startDate, endDate)
            .sorted(byKeyPath: "date", ascending: true)

        return Array(results)
    }

    func observeIsEmpty<T: Object>(_ type: T.Type) -> Observable<Bool> {
        return Observable.create { observer in
            guard let realm = try? self.getRealm() else {
                observer.onNext(true)
                observer.onCompleted()
                return Disposables.create()
            }

            let results = realm.objects(type)
            observer.onNext(results.isEmpty)

            let token = results.observe { change in
                switch change {
                case .initial(let collection):
                    observer.onNext(collection.isEmpty)
                case .update(let collection, _, _, _):
                    observer.onNext(collection.isEmpty)
                case .error(let error):
                    observer.onError(error)
                }
            }

            return Disposables.create {
                token.invalidate()
            }
        }
    }

    func observeCards(for period: DatePeriod) -> Observable<[CardCalendarItemDTO]> {
        return Observable.create { observer in
            guard let realm = try? self.getRealm() else {
                observer.onNext([])
                observer.onCompleted()
                return Disposables.create()
            }

            let calendar = Calendar.current
            let startDate: Date
            let endDate: Date

            switch period {
            case .day(let date):
                startDate = calendar.startOfDay(for: date)
                guard let end = calendar.date(byAdding: .day, value: 1, to: startDate) else {
                    observer.onNext([])
                    observer.onCompleted()
                    return Disposables.create()
                }
                endDate = end

            case .month(let date):
                guard let start = calendar.date(from: calendar.dateComponents([.year, .month], from: date)),
                      let end = calendar.date(byAdding: .month, value: 1, to: start) else {
                    observer.onNext([])
                    observer.onCompleted()
                    return Disposables.create()
                }
                startDate = start
                endDate = end
            }

            let results = realm.objects(Card.self)
                .filter("date >= %@ AND date < %@", startDate, endDate)
                .sorted(byKeyPath: "date", ascending: true)

            let token = results.observe { change in
                switch change {
                case .initial(let collection):
                    MemoryTracker.measure("RealmObserve.initial.before")
                    let dtos = Array(collection).map { CardCalendarItemDTO(from: $0) }
                    MemoryTracker.measure("RealmObserve.initial.after")
                    MemoryTracker.compare("RealmObserve.initial.before", "RealmObserve.initial.after")
                    observer.onNext(dtos)
                case .update(let collection, _, _, _):
                    let dtos = Array(collection).map { CardCalendarItemDTO(from: $0) }
                    observer.onNext(dtos)
                case .error(let error):
                    observer.onError(error)
                }
            }

            return Disposables.create {
                token.invalidate()
            }
        }
    }

    func observeAllCards() -> Observable<[Card]> {
        return Observable.create { observer in
            guard let realm = try? self.getRealm() else {
                observer.onNext([])
                observer.onCompleted()
                return Disposables.create()
            }

            let results = realm.objects(Card.self)

            let token = results.observe { change in
                switch change {
                case .initial(let collection):
                    observer.onNext(Array(collection))
                case .update(let collection, _, _, _):
                    observer.onNext(Array(collection))
                case .error(let error):
                    observer.onError(error)
                }
            }

            return Disposables.create {
                token.invalidate()
            }
        }
    }
    func observeCards(withIds ids: [ObjectId]) -> Observable<[CardListItemDTO]> {
        return Observable.create { observer in
            guard let realm = try? self.getRealm() else {
                observer.onNext([])
                observer.onCompleted()
                return Disposables.create()
            }

            let results = realm.objects(Card.self).filter("id IN %@", ids)

            let token = results.observe { change in
                switch change {
                case .initial(let collection), .update(let collection, _, _, _):
                    let sorted = Array(collection).sorted { $0.date > $1.date }
                    observer.onNext(sorted.map { CardListItemDTO(from: $0) })
                case .error(let error):
                    observer.onError(error)
                }
            }

            return Disposables.create {
                token.invalidate()
            }
        }
    }

    func observeCards(inFolder folderName: String?) -> Observable<[CardListItemDTO]> {
        return Observable.create { observer in
            guard let realm = try? self.getRealm() else {
                observer.onNext([])
                observer.onCompleted()
                return Disposables.create()
            }

            let results: Results<Card>
            let defaultFolderName = NSLocalizedString("folder.default", comment: "")

            if let folderName = folderName, folderName == defaultFolderName {
                results = realm.objects(Card.self).filter("customFolder == nil OR customFolder == ''")
            } else if let folderName = folderName {
                results = realm.objects(Card.self).filter("customFolder == %@", folderName)
            } else {
                results = realm.objects(Card.self)
            }

            let token = results.observe { change in
                switch change {
                case .initial(let collection), .update(let collection, _, _, _):
                    let sorted = Array(collection).sorted { $0.date > $1.date }
                    observer.onNext(sorted.map { CardListItemDTO(from: $0) })
                case .error(let error):
                    observer.onError(error)
                }
            }

            return Disposables.create {
                token.invalidate()
            }
        }
    }

    func fetchImageData(for cardId: ObjectId) -> Data? {
        guard let realm = try? getRealm() else { return nil }
        guard let card = realm.object(ofType: Card.self, forPrimaryKey: cardId) else { return nil }
        guard let resolvedData = card.resolvedImageData() else { return nil }

        if card.imagePath != nil {
            Logger.database.info("[ImageStorage] Loaded from disk: \(card.imagePath!)")
            return resolvedData
        }

        Logger.database.notice("[ImageStorage] Loaded from Realm (\(resolvedData.count / 1024)KB), starting lazy migration...")

        // Lazy migration: 기존 Realm 데이터를 백그라운드에서 디스크로 이전
        let format = card.imageFormat ?? "jpeg"
        let dataCopy = Data(resolvedData)
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }
            do {
                let fileName = try ImageFileService.shared.saveImageFile(data: dataCopy, cardId: cardId, format: format)
                _ = self.update { realm in
                    guard let card = realm.object(ofType: Card.self, forPrimaryKey: cardId) else { return }
                    card.imagePath = fileName
                    card.editedImageData = nil
                }
                Logger.database.notice("[ImageStorage] Lazy migration done: \(fileName)")
            } catch {
                // 디스크 저장 실패 시 Realm에 유지 — 다음 접근 시 재시도
            }
        }

        return resolvedData
    }

    func deleteCard(forPrimaryKey key: ObjectId) -> Observable<Void> {
        let imagePath = fetchObject(Card.self, forPrimaryKey: key)?.imagePath

        return delete(Card.self, forPrimaryKey: key)
            .do(onNext: { [weak self] in
                if let imagePath = imagePath {
                    ImageFileService.shared.deleteImageFile(at: imagePath)
                }
                ThumbnailCache.shared.invalidate(for: key)
                self?.syncService?.notifyChange(recordID: key.stringValue, type: .delete)
            })
    }

    func allImagePaths() -> Set<String> {
        guard let realm = try? getRealm() else { return [] }
        let cards = realm.objects(Card.self).filter("imagePath != nil")
        return Set(cards.compactMap(\.imagePath))
    }

    func migrateAllLegacyImagesToDisk(imageFileService: ImageFileServiceProtocol) throws {
        let realm = try getRealm()
        let legacyCards = realm.objects(Card.self).filter("imagePath == nil AND editedImageData != nil")

        guard !legacyCards.isEmpty else { return }

        logger.notice("Migrating \(legacyCards.count) legacy images to disk")

        for card in legacyCards {
            autoreleasepool {
                guard let imageData = card.editedImageData else { return }
                let format = card.imageFormat ?? "jpeg"
                do {
                    let fileName = try imageFileService.saveImageFile(data: imageData, cardId: card.id, format: format)
                    try realm.write {
                        card.imagePath = fileName
                        card.editedImageData = nil
                    }
                } catch {
                    logger.error("Legacy migration failed for card \(card.id): \(error.localizedDescription)")
                }
            }
        }
    }
}

enum RealmError: Error {
    case objectNotFound
    case writeError
    case configurationError
}

final class MockRealmService: RealmServiceProtocol {
    var objects: [Object] = []
    var shouldThrowError = false

    func add<T: Object>(_ object: T) -> Observable<Void> {
        return Observable.create { observer in
            if self.shouldThrowError {
                observer.onError(RealmError.writeError)
            } else {
                self.objects.append(object)
                observer.onNext(())
                observer.onCompleted()
            }
            return Disposables.create()
        }
    }

    func fetch<T: Object>(_ type: T.Type, filter: String?, sortKey: String?, ascending: Bool) -> [T] {
        return objects.compactMap { $0 as? T }
    }

    func fetchObject<T: Object>(_ type: T.Type, forPrimaryKey key: Any) -> T? {
        return objects.compactMap { $0 as? T }.first
    }

    func delete<T: Object>(_ object: T) -> Observable<Void> {
        return Observable.create { observer in
            if self.shouldThrowError {
                observer.onError(RealmError.writeError)
            } else {
                self.objects.removeAll { $0.isSameObject(as: object) }
                observer.onNext(())
                observer.onCompleted()
            }
            return Disposables.create()
        }
    }

    func delete<T: Object>(_ type: T.Type, forPrimaryKey key: Any) -> Observable<Void> {
        return Observable.create { observer in
            if self.shouldThrowError {
                observer.onError(RealmError.objectNotFound)
            } else {
                self.objects.removeAll { $0 is T }
                observer.onNext(())
                observer.onCompleted()
            }
            return Disposables.create()
        }
    }

    func update(_ block: @escaping (Realm) -> Void) -> Observable<Void> {
        return Observable.create { observer in
            if self.shouldThrowError {
                observer.onError(RealmError.writeError)
            } else {
                observer.onNext(())
                observer.onCompleted()
            }
            return Disposables.create()
        }
    }

    func isEmpty<T: Object>(_ type: T.Type) -> Bool {
        return objects.compactMap { $0 as? T }.isEmpty
    }

    func fetchCards(for period: DatePeriod) -> [Card] {
        return objects.compactMap { $0 as? Card }
    }

    func observeIsEmpty<T: Object>(_ type: T.Type) -> Observable<Bool> {
        return Observable.just(isEmpty(type))
    }

    func observeCards(for period: DatePeriod) -> Observable<[CardCalendarItemDTO]> {
        let cards = fetchCards(for: period)
        let dtos = cards.map { CardCalendarItemDTO(from: $0) }
        return Observable.just(dtos)
    }

    func observeAllCards() -> Observable<[Card]> {
        return Observable.just(objects.compactMap { $0 as? Card })
    }

    func observeCards(withIds ids: [ObjectId]) -> Observable<[CardListItemDTO]> {
        let cards = objects.compactMap { $0 as? Card }.filter { ids.contains($0.id) }
        return Observable.just(cards.map { CardListItemDTO(from: $0) })
    }

    func observeCards(inFolder folderName: String?) -> Observable<[CardListItemDTO]> {
        let cards = objects.compactMap { $0 as? Card }
        return Observable.just(cards.map { CardListItemDTO(from: $0) })
    }

    func fetchImageData(for cardId: ObjectId) -> Data? {
        guard let card = objects.first(where: { ($0 as? Card)?.id == cardId }) as? Card else {
            return nil
        }
        return card.resolvedImageData()
    }

    func deleteCard(forPrimaryKey key: ObjectId) -> Observable<Void> {
        return delete(Card.self, forPrimaryKey: key)
    }

    func createConfiguration() -> Realm.Configuration {
        var config = Realm.Configuration.defaultConfiguration
        config.inMemoryIdentifier = "MockRealm"
        return config
    }

    func migrateAllLegacyImagesToDisk(imageFileService: ImageFileServiceProtocol) throws {}

    func allImagePaths() -> Set<String> {
        return Set(objects.compactMap { ($0 as? Card)?.imagePath })
    }
}
