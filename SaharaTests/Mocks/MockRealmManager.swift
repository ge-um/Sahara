//
//  MockRealmManager.swift
//  SaharaTests
//
//  Created by 금가경 on 10/20/25.
//

import Foundation
import RealmSwift
import RxSwift
@testable import Sahara

final class MockRealmManager: RealmManagerProtocol {
    var addCalled = false
    var fetchCalled = false
    var deleteCalled = false
    var updateCalled = false
    var isEmptyCalled = false

    var mockCards: [Card] = []
    var mockIsEmpty = true
    var shouldFailAdd = false
    var shouldFailDelete = false
    var shouldFailUpdate = false

    func add<T: Object>(_ object: T) -> Observable<Void> {
        addCalled = true

        if shouldFailAdd {
            return Observable.error(NSError(domain: "MockError", code: -1))
        }

        if let card = object as? Card {
            mockCards.append(card)
            mockIsEmpty = false
        }

        return Observable.just(())
    }

    func fetch<T: Object>(_ type: T.Type, filter: String?, sortKey: String?, ascending: Bool) -> [T] {
        fetchCalled = true
        return mockCards as? [T] ?? []
    }

    func fetchObject<T: Object>(_ type: T.Type, forPrimaryKey key: Any) -> T? {
        if type == Card.self, let objectId = key as? ObjectId {
            return mockCards.first(where: { $0.id == objectId }) as? T
        }
        return nil
    }

    func delete<T: Object>(_ object: T) -> Observable<Void> {
        deleteCalled = true

        if shouldFailDelete {
            return Observable.error(NSError(domain: "MockError", code: -1))
        }

        if let card = object as? Card {
            mockCards.removeAll { $0.id == card.id }
            mockIsEmpty = mockCards.isEmpty
        }

        return Observable.just(())
    }

    func delete<T: Object>(_ type: T.Type, forPrimaryKey key: Any) -> Observable<Void> {
        deleteCalled = true

        if shouldFailDelete {
            return Observable.error(NSError(domain: "MockError", code: -1))
        }

        if type == Card.self, let objectId = key as? ObjectId {
            mockCards.removeAll { $0.id == objectId }
            mockIsEmpty = mockCards.isEmpty
        }

        return Observable.just(())
    }

    func update(_ block: @escaping (Realm) -> Void) -> Observable<Void> {
        updateCalled = true

        if shouldFailUpdate {
            return Observable.error(NSError(domain: "MockError", code: -1))
        }

        return Observable.just(())
    }

    func isEmpty<T: Object>(_ type: T.Type) -> Bool {
        isEmptyCalled = true
        return mockIsEmpty
    }

    func fetchCards(for period: DatePeriod) -> [Card] {
        return mockCards
    }

    func observeIsEmpty<T: Object>(_ type: T.Type) -> Observable<Bool> {
        return Observable.just(mockIsEmpty)
    }

    func observeCards(for period: DatePeriod) -> Observable<[CardCalendarItemDTO]> {
        return Observable.just([])
    }

    func observeAllCards() -> Observable<[Card]> {
        return Observable.just(mockCards)
    }

    func reset() {
        addCalled = false
        fetchCalled = false
        deleteCalled = false
        updateCalled = false
        isEmptyCalled = false
        mockCards = []
        mockIsEmpty = true
        shouldFailAdd = false
        shouldFailDelete = false
        shouldFailUpdate = false
    }
}
