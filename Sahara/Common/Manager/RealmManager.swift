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
}

extension RealmManagerProtocol {
    func fetch<T: Object>(_ type: T.Type) -> [T] {
        return fetch(type, filter: nil, sortKey: nil, ascending: true)
    }
}

final class RealmManager: RealmManagerProtocol {
    static let shared = RealmManager()

    private let configuration: Realm.Configuration

    init(configuration: Realm.Configuration = .defaultConfiguration) {
        self.configuration = configuration
    }

    private func getRealm() throws -> Realm {
        return try Realm(configuration: configuration)
    }

    func add<T: Object>(_ object: T) -> Observable<Void> {
        return Observable.create { observer in
            DispatchQueue.main.async {
                do {
                    let realm = try self.getRealm()
                    realm.writeAsync {
                        realm.add(object)
                    } onComplete: { error in
                        if let error = error {
                            observer.onError(error)
                        } else {
                            observer.onNext(())
                            observer.onCompleted()
                        }
                    }
                } catch {
                    observer.onError(error)
                }
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
            DispatchQueue.main.async {
                do {
                    let realm = try self.getRealm()
                    realm.writeAsync {
                        realm.delete(object)
                    } onComplete: { error in
                        if let error = error {
                            observer.onError(error)
                        } else {
                            observer.onNext(())
                            observer.onCompleted()
                        }
                    }
                } catch {
                    observer.onError(error)
                }
            }
            return Disposables.create()
        }
    }

    func delete<T: Object>(_ type: T.Type, forPrimaryKey key: Any) -> Observable<Void> {
        return Observable.create { observer in
            DispatchQueue.main.async {
                do {
                    let realm = try self.getRealm()
                    guard let object = realm.object(ofType: type, forPrimaryKey: key) else {
                        observer.onError(RealmError.objectNotFound)
                        return
                    }
                    realm.writeAsync {
                        realm.delete(object)
                    } onComplete: { error in
                        if let error = error {
                            observer.onError(error)
                        } else {
                            observer.onNext(())
                            observer.onCompleted()
                        }
                    }
                } catch {
                    observer.onError(error)
                }
            }
            return Disposables.create()
        }
    }

    func update(_ block: @escaping (Realm) -> Void) -> Observable<Void> {
        return Observable.create { observer in
            DispatchQueue.main.async {
                do {
                    let realm = try self.getRealm()
                    realm.writeAsync {
                        block(realm)
                    } onComplete: { error in
                        if let error = error {
                            observer.onError(error)
                        } else {
                            observer.onNext(())
                            observer.onCompleted()
                        }
                    }
                } catch {
                    observer.onError(error)
                }
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
            .filter("createdDate >= %@ AND createdDate < %@", startDate, endDate)
            .sorted(byKeyPath: "createdDate", ascending: true)

        return Array(results)
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
}
