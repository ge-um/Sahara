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

    private var realm: Realm? {
        do {
            return try Realm()
        } catch {
            print("Realm 초기화 실패: \(error)")
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
            print("Realm 저장 실패: \(error)")
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
            print("Realm 삭제 실패: \(error)")
        }
    }

    func update(_ block: () -> Void) {
        do {
            try realm?.write {
                block()
            }
        } catch {
            print("Realm 업데이트 실패: \(error)")
        }
    }
}