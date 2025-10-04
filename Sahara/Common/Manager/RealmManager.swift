//
//  RealmManager.swift
//  Sahara
//
//  Created by 금가경 on 9/26/25.
//

import Foundation
import RealmSwift

final class RealmManager {
    static let shared = RealmManager()

    var realm: Realm? {
        do {
            return try Realm()
        } catch {
            return nil
        }
    }

    private init() {}

    func save<T: Object>(_ object: T) {
        do {
            try realm?.write {
                realm?.add(object)
            }
        } catch {
        }
    }

    func fetch<T: Object>(_ type: T.Type) -> Results<T>? {
        return realm?.objects(type)
    }

    func delete<T: Object>(_ object: T) {
        do {
            try realm?.write {
                realm?.delete(object)
            }
        } catch {
        }
    }

    func update(_ block: () -> Void) {
        do {
            try realm?.write {
                block()
            }
        } catch {
        }
    }

    func fetchMemos(on date: Date) -> [Card] {
        guard let realm = realm else { return [] }
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return []
        }

        let results = realm.objects(Card.self)
            .filter("createdDate >= %@ AND createdDate < %@", startOfDay, endOfDay)
            .sorted(byKeyPath: "createdDate", ascending: true)

        return Array(results)
    }

    func fetchMemos(in month: Date) -> [Card] {
        guard let realm = realm else { return [] }
        let calendar = Calendar.current
        guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: month)),
              let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) else {
            return []
        }

        let results = realm.objects(Card.self)
            .filter("createdDate >= %@ AND createdDate <= %@", startOfMonth, endOfMonth)
            .sorted(byKeyPath: "createdDate", ascending: true)

        return Array(results)
    }

    func isEmpty<T: Object>(_ type: T.Type) -> Bool {
        return realm?.objects(type).isEmpty ?? true
    }
}
