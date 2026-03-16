//
//  CloudSyncProtocol.swift
//  Sahara
//

import Foundation

enum CloudSyncChangeType {
    case save
    case delete
}

enum CloudSyncStatus: Equatable {
    case disabled
    case syncing
    case upToDate
    case error(String)
    case accountUnavailable
}

protocol CloudSyncServiceProtocol: AnyObject {
    var isEnabled: Bool { get }
    var isSyncing: Bool { get }
    var lastSyncDate: Date? { get }
    var status: CloudSyncStatus { get }

    func startSync()
    func stopSync()
    func notifyChange(recordID: String, type: CloudSyncChangeType)
    func triggerFullSync()
    func checkAccountStatus(completion: @escaping (Bool) -> Void)
    func fetchChangesIfNeeded()
}

extension Notification.Name {
    static let cloudSyncStatusChanged = Notification.Name("cloudSyncStatusChanged")
}
