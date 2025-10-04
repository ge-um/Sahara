//
//  AppNotification.swift
//  Sahara
//
//  Created by 금가경 on 10/2/25.
//

import Foundation

enum AppNotification: String {
    case photoSaved = "PhotoSaved"
    case photoDeleted = "PhotoDeleted"

    var name: Notification.Name {
        return Notification.Name(rawValue)
    }
}
