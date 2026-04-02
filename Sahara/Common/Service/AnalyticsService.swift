//
//  AnalyticsService.swift
//  Sahara
//
//  Created by 금가경 on 10/6/25.
//

import FirebaseAnalytics
import Foundation
import WidgetKit

enum AnalyticsEvent: String {
    case photoEditToolUsed = "photo_edit_tool_used"
    case photoEditComplete = "photo_edit_complete"

    case galleryViewChanged = "gallery_view_changed"

    case biometricEnabled = "biometric_enabled"
    case biometricAuthResult = "biometric_auth_result"

    case usageStreak = "usage_streak"

    case notificationSettingChanged = "notification_setting_changed"

    case cardCreated = "card_created"
    case cardViewed = "card_viewed"
    case appOpenSource = "app_open_source"

    case themeSettingsViewed = "theme_settings_viewed"
    case themeChanged = "theme_changed"

    case widgetConfigured = "widget_configured"

    case remoteConfigFetchFailed = "remote_config_fetch_failed"
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

    case totalCardCount = "total_card_count"
    case cardAgeDays = "card_age_days"
    case source = "source"

    case previousTheme = "previous_theme"
    case newTheme = "new_theme"
    case previousThemeDetail = "previous_theme_detail"
    case newThemeDetail = "new_theme_detail"
    case experimentGroup = "experiment_group"

    case widgetCount = "widget_count"
    case widgetFamilies = "widget_families"
}

final class AnalyticsService {
    static let shared = AnalyticsService()

    private enum Keys {
        static let lastActiveDate = "analytics_last_active_date"
        static let usageStreakCount = "analytics_usage_streak"
        static let appFirstLaunchDate = "analytics_app_first_launch_date"
        static let lastWidgetCount = "analytics_last_widget_count"
        static let hasCustomizedTheme = "has_customized_theme"
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

    func logUsageStreak(days: Int) {
        logEvent(.usageStreak, parameters: [.days: days])
    }

    func logNotificationSettingChanged(type: String, enabled: Bool) {
        var params: [AnalyticsParameter: Any] = [
            .type: type,
            .success: enabled
        ]

        if let days = calculateDaysSinceInstall() {
            params[.daysSinceInstall] = days
        }

        logEvent(.notificationSettingChanged, parameters: params)
    }

    func logCardCreated(totalCardCount: Int) {
        var params: [AnalyticsParameter: Any] = [
            .totalCardCount: totalCardCount
        ]

        if let days = calculateDaysSinceInstall() {
            params[.daysSinceInstall] = days
        }

        logEvent(.cardCreated, parameters: params)
    }

    func logCardViewed(cardAgeDays: Int) {
        logEvent(.cardViewed, parameters: [.cardAgeDays: cardAgeDays])
    }

    func logAppOpenSource(source: String) {
        logEvent(.appOpenSource, parameters: [.source: source])
    }

    func logThemeSettingsViewed() {
        logEvent(.themeSettingsViewed)
    }

    func logThemeChanged(previousTheme: String, newTheme: String, previousDetail: String, newDetail: String) {
        var params: [AnalyticsParameter: Any] = [
            .previousTheme: previousTheme,
            .newTheme: newTheme,
            .previousThemeDetail: previousDetail,
            .newThemeDetail: newDetail,
            .experimentGroup: RemoteConfigService.shared.fetchDefaultThemeVariant().rawValue
        ]

        if let days = calculateDaysSinceInstall() {
            params[.daysSinceInstall] = days
        }

        logEvent(.themeChanged, parameters: params)
    }

    func checkWidgetStatus() {
        WidgetCenter.shared.getCurrentConfigurations { [weak self] result in
            guard let self else { return }

            let widgets: [WidgetInfo]
            switch result {
            case .success(let infos):
                widgets = infos
            case .failure:
                return
            }

            let currentCount = widgets.count
            Analytics.setUserProperty(String(currentCount), forName: AnalyticsParameter.widgetCount.rawValue)

            let lastCount = UserDefaults.standard.integer(forKey: Keys.lastWidgetCount)
            if currentCount != lastCount {
                let uniqueFamilies = Set(widgets.map { widget -> String in
                    switch widget.family {
                    case .systemSmall: return "small"
                    case .systemLarge: return "large"
                    default: return "unknown"
                    }
                }).sorted().joined(separator: ",")

                var params: [AnalyticsParameter: Any] = [
                    .widgetCount: currentCount,
                    .widgetFamilies: uniqueFamilies
                ]

                if let days = self.calculateDaysSinceInstall() {
                    params[.daysSinceInstall] = days
                }

                self.logEvent(.widgetConfigured, parameters: params)
                UserDefaults.standard.set(currentCount, forKey: Keys.lastWidgetCount)
            }
        }
    }

    func setHasCustomizedThemeProperty(_ value: Bool) {
        Analytics.setUserProperty(value ? "true" : "false", forName: Keys.hasCustomizedTheme)
    }

    private func calculateDaysSinceInstall() -> Int? {
        guard let firstLaunchDate = UserDefaults.standard.object(forKey: Keys.appFirstLaunchDate) as? Date else {
            return nil
        }
        return Calendar.current.dateComponents([.day], from: firstLaunchDate, to: Date()).day
    }
}
