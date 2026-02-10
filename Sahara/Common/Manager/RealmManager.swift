//
//  RealmManager.swift
//  Sahara
//
//  Created by 금가경 on 9/26/25.
//

import Foundation
import RealmSwift
import RxSwift

enum DatePeriod {
    case day(Date)
    case month(Date)
}

protocol RealmManagerProtocol {
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
}

extension RealmManagerProtocol {
    func fetch<T: Object>(_ type: T.Type) -> [T] {
        return fetch(type, filter: nil, sortKey: nil, ascending: true)
    }
}

final class RealmManager: RealmManagerProtocol {
    static let shared = RealmManager()

    private let configuration: Realm.Configuration

    static let currentSchemaVersion: UInt64 = 2

    init(configuration: Realm.Configuration = .defaultConfiguration) {
        self.configuration = configuration
    }

    static func createConfiguration(schemaVersion: UInt64 = currentSchemaVersion, migrationBlock: MigrationBlock? = nil) -> Realm.Configuration {
        var config = Realm.Configuration()
        config.schemaVersion = schemaVersion
        config.migrationBlock = migrationBlock ?? defaultMigrationBlock
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
                    let dtos = Array(collection).map { CardCalendarItemDTO(from: $0) }
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
}

enum RealmError: Error {
    case objectNotFound
    case writeError
    case configurationError
}

final class MockRealmManager: RealmManagerProtocol {
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
}
