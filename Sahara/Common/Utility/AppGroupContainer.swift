//
//  AppGroupContainer.swift
//  Sahara
//
//  Created by 금가경 on 3/11/26.
//

import Foundation

enum AppGroupContainer {
    static let groupIdentifier = "group.com.miya.Sahara"
    static let widgetURLScheme = "saharaapp"

    static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupIdentifier)
    }

    static var widgetDirectory: URL? {
        containerURL?.appendingPathComponent("widget", isDirectory: true)
    }

    static var thumbnailsDirectory: URL? {
        widgetDirectory?.appendingPathComponent("thumbnails", isDirectory: true)
    }

    static var cardStoreURL: URL? {
        widgetDirectory?.appendingPathComponent("WidgetCardStore.json")
    }

    private static var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: groupIdentifier)
    }

    static var pinnedCardId: String? {
        get { sharedDefaults?.string(forKey: "pinnedCardId") }
        set {
            sharedDefaults?.set(newValue, forKey: "pinnedCardId")
        }
    }
}
