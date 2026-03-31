//
//  AnalyticsService.swift
//  Sahara
//
//  Created by 금가경 on 10/6/25.
//

import FirebaseAnalytics
import Foundation

enum AnalyticsEvent: String {
    case photoEditToolUsed = "photo_edit_tool_used"
    case photoEditComplete = "photo_edit_complete"

    case galleryViewChanged = "gallery_view_changed"

    case biometricEnabled = "biometric_enabled"
    case biometricAuthResult = "biometric_auth_result"

    case firstCardCreated = "first_card_created"

    case usageStreak = "usage_streak"

    case notificationSettingChanged = "notification_setting_changed"
}

enum AnalyticsParameter: String {
    case tool = "tool"
    case toolsUsedCount = "tools_used_count"

    case viewType = "view_type"

    case type = "type"
    case success = "success"
    case feature = "feature"

    case days = "days"
    case daysSinceInstall = "days_since_install"
}

final class AnalyticsService {
    static let shared = AnalyticsService()

    private enum Keys {
        static let lastActiveDate = "analytics_last_active_date"
        static let usageStreakCount = "analytics_usage_streak"
        static let appFirstLaunchDate = "analytics_app_first_launch_date"
    }

    private init() {}

    func registerFirstLaunchDateIfNeeded() {
        if UserDefaults.standard.object(forKey: Keys.appFirstLaunchDate) == nil {
            UserDefaults.standard.set(Date(), forKey: Keys.appFirstLaunchDate)
        }
    }

    func trackDailyUsage() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let lastActive = UserDefaults.standard.object(forKey: Keys.lastActiveDate) as? Date

        if let lastActive = lastActive {
            let lastActiveDay = calendar.startOfDay(for: lastActive)
            if lastActiveDay == today { return }

            if let yesterday = calendar.date(byAdding: .day, value: -1, to: today),
               lastActiveDay == yesterday {
                let streak = UserDefaults.standard.integer(forKey: Keys.usageStreakCount) + 1
                UserDefaults.standard.set(streak, forKey: Keys.usageStreakCount)
                logUsageStreak(days: streak)
            } else {
                UserDefaults.standard.set(1, forKey: Keys.usageStreakCount)
                logUsageStreak(days: 1)
            }
        } else {
            UserDefaults.standard.set(1, forKey: Keys.usageStreakCount)
            logUsageStreak(days: 1)
        }

        UserDefaults.standard.set(today, forKey: Keys.lastActiveDate)
    }

    func logEvent(_ event: AnalyticsEvent, parameters: [AnalyticsParameter: Any]? = nil) {
        var firebaseParameters: [String: Any]? = nil

        if let parameters = parameters {
            firebaseParameters = Dictionary(uniqueKeysWithValues: parameters.map { ($0.key.rawValue, $0.value) })
        }

        Analytics.logEvent(event.rawValue, parameters: firebaseParameters)
    }

    func logPhotoEditToolUsed(tool: String) {
        logEvent(.photoEditToolUsed, parameters: [.tool: tool])
    }

    func logPhotoEditComplete(toolsUsedCount: Int) {
        logEvent(.photoEditComplete, parameters: [.toolsUsedCount: toolsUsedCount])
    }

    func logGalleryViewChanged(viewType: String) {
        logEvent(.galleryViewChanged, parameters: [.viewType: viewType])
    }

    func logBiometricEnabled(type: String) {
        logEvent(.biometricEnabled, parameters: [.type: type])
    }

    func logBiometricAuthResult(success: Bool, feature: String) {
        logEvent(.biometricAuthResult, parameters: [
            .success: success,
            .feature: feature
        ])
    }

    func logFirstCardCreated() {
        logEvent(.firstCardCreated)
    }

    func logUsageStreak(days: Int) {
        logEvent(.usageStreak, parameters: [.days: days])
    }

    func logNotificationSettingChanged(type: String, enabled: Bool) {
        var params: [AnalyticsParameter: Any] = [
            .type: type,
            .success: enabled
        ]

        if let firstLaunchDate = UserDefaults.standard.object(forKey: Keys.appFirstLaunchDate) as? Date {
            let daysSinceInstall = Calendar.current.dateComponents([.day], from: firstLaunchDate, to: Date()).day ?? 0
            params[.daysSinceInstall] = daysSinceInstall
        }

        logEvent(.notificationSettingChanged, parameters: params)
    }
}
