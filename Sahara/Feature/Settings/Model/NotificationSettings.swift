//
//  NotificationSettings.swift
//  Sahara
//

import Foundation
import UserNotifications
import FirebaseMessaging

final class NotificationSettings {
    static let shared = NotificationSettings()

    private let userDefaults = UserDefaults.standard

    private enum Keys {
        static let serviceNewsEnabled = "notification_service_news_enabled"
    }

    private init() {}

    func checkSystemNotificationPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(settings.authorizationStatus == .authorized)
            }
        }
    }

    var isServiceNewsEnabled: Bool {
        get {
            return userDefaults.bool(forKey: Keys.serviceNewsEnabled)
        }
        set {
            let oldValue = userDefaults.bool(forKey: Keys.serviceNewsEnabled)
            userDefaults.set(newValue, forKey: Keys.serviceNewsEnabled)

            if oldValue != newValue {
                if newValue {
                    subscribeToServiceNews()
                } else {
                    unsubscribeFromServiceNews()
                }
            }
        }
    }

    func setServiceNewsEnabledWithoutSubscription(_ enabled: Bool) {
        userDefaults.set(enabled, forKey: Keys.serviceNewsEnabled)
    }

    func subscribeToServiceNews() {
        Messaging.messaging().subscribe(toTopic: "service_news") { error in
        }
    }

    func unsubscribeFromServiceNews() {
        Messaging.messaging().unsubscribe(fromTopic: "service_news") { error in
        }
    }
}
