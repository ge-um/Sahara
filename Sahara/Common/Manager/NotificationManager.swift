//
//  NotificationManager.swift
//  Sahara
//

import Foundation
import FirebaseMessaging
import UserNotifications
import UIKit

final class NotificationManager: NSObject {
    static let shared = NotificationManager()

    private let userDefaults = UserDefaults.standard

    private enum Keys {
        static let fcmToken = "fcm_token"
    }

    private override init() {
        super.init()
    }

    func getFCMToken(completion: @escaping (String?) -> Void) {
        Messaging.messaging().token { token, error in
            completion(token)
        }
    }

    func getSavedFCMToken() -> String? {
        return userDefaults.string(forKey: Keys.fcmToken)
    }
}
