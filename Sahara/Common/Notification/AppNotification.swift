//
//  AppNotification.swift
//  Sahara
//
//  Created by 금가경 on 10/2/25.
//

import Foundation

enum AppNotification {
    case photoSaved
    case photoDeleted

    var name: Notification.Name {
        switch self {
        case .photoSaved:
            return Notification.Name("PhotoSaved")
        case .photoDeleted:
            return Notification.Name("PhotoDeleted")
        }
    }
}
