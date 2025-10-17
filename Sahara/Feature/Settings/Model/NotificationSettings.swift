//
//  NotificationSettings.swift
//  Sahara
//

import Foundation
import UserNotifications

final class NotificationSettings {
    static let shared = NotificationSettings()

    private let userDefaults = UserDefaults.standard

    private enum Keys {
        static let weeklyReportEnabled = "notification_weekly_report_enabled"
    }

    private init() {}

    func checkSystemNotificationPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(settings.authorizationStatus == .authorized)
            }
        }
    }


    var isWeeklyReportEnabled: Bool {
        get {
            return userDefaults.bool(forKey: Keys.weeklyReportEnabled)
        }
        set {
            userDefaults.set(newValue, forKey: Keys.weeklyReportEnabled)
        }
    }
}
