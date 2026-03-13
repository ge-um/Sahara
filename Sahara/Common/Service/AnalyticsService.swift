//
//  AnalyticsService.swift
//  Sahara
//
//  Created by 금가경 on 10/6/25.
//

import FirebaseAnalytics
import Foundation

enum AnalyticsEvent: String {
    case cardSaveSuccess = "card_save_success"
    case cardDelete = "card_delete"
    case cardEdit = "card_edit"

    case photoSourceSelected = "photo_source_selected"
    case photoEditToolUsed = "photo_edit_tool_used"
    case photoEditComplete = "photo_edit_complete"

    case galleryViewChanged = "gallery_view_changed"
    case calendarDateRangeViewed = "calendar_date_range_viewed"

    case biometricEnabled = "biometric_enabled"
    case biometricAuthResult = "biometric_auth_result"

    case locationSearchUsed = "location_search_used"
    case locationSaved = "location_saved"
    case mapLocationViewed = "map_location_viewed"

    case firstCardCreated = "first_card_created"
    case firstLocationAdded = "first_location_added"

    case usageStreak = "usage_streak"
    case dailyCardsCreated = "daily_cards_created"

    case photoLoadError = "photo_load_error"
    case locationPermissionDenied = "location_permission_denied"
    case biometricPermissionDenied = "biometric_permission_denied"

    case tabSelected = "tab_selected"

    case notificationOpened = "notification_opened"
    case notificationSettingChanged = "notification_setting_changed"
    case fcmTokenRegistered = "fcm_token_registered"
}

enum AnalyticsParameter: String {
    case hasPhoto = "has_photo"
    case hasMemo = "has_memo"
    case hasLocation = "has_location"
    case isLocked = "is_locked"
    case editType = "edit_type"

    case source = "source"
    case tool = "tool"
    case toolsUsedCount = "tools_used_count"

    case viewType = "view_type"
    case year = "year"
    case month = "month"

    case type = "type"
    case success = "success"
    case feature = "feature"

    case cardsCount = "cards_count"
    case days = "days"
    case count = "count"

    case errorType = "error_type"

    case tabName = "tab_name"
}

final class AnalyticsService {
    static let shared = AnalyticsService()

    private init() {}

    func logEvent(_ event: AnalyticsEvent, parameters: [AnalyticsParameter: Any]? = nil) {
        var firebaseParameters: [String: Any]? = nil

        if let parameters = parameters {
            firebaseParameters = Dictionary(uniqueKeysWithValues: parameters.map { ($0.key.rawValue, $0.value) })
        }

        Analytics.logEvent(event.rawValue, parameters: firebaseParameters)
    }

    func logCardSave(hasPhoto: Bool, hasMemo: Bool, hasLocation: Bool, isLocked: Bool) {
        logEvent(.cardSaveSuccess, parameters: [
            .hasPhoto: hasPhoto,
            .hasMemo: hasMemo,
            .hasLocation: hasLocation,
            .isLocked: isLocked
        ])
    }

    func logCardDelete() {
        logEvent(.cardDelete)
    }

    func logCardEdit(editType: String) {
        logEvent(.cardEdit, parameters: [.editType: editType])
    }

    func logPhotoSourceSelected(source: String) {
        logEvent(.photoSourceSelected, parameters: [.source: source])
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

    func logCalendarDateRangeViewed(year: Int, month: Int) {
        logEvent(.calendarDateRangeViewed, parameters: [
            .year: year,
            .month: month
        ])
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

    func logLocationSearchUsed() {
        logEvent(.locationSearchUsed)
    }

    func logLocationSaved(source: String) {
        logEvent(.locationSaved, parameters: [.source: source])
    }

    func logMapLocationViewed(cardsCount: Int) {
        logEvent(.mapLocationViewed, parameters: [.cardsCount: cardsCount])
    }

    func logFirstCardCreated() {
        logEvent(.firstCardCreated)
    }

    func logFirstLocationAdded() {
        logEvent(.firstLocationAdded)
    }

    func logUsageStreak(days: Int) {
        logEvent(.usageStreak, parameters: [.days: days])
    }

    func logDailyCardsCreated(count: Int) {
        logEvent(.dailyCardsCreated, parameters: [.count: count])
    }

    func logPhotoLoadError(errorType: String) {
        logEvent(.photoLoadError, parameters: [.errorType: errorType])
    }

    func logLocationPermissionDenied() {
        logEvent(.locationPermissionDenied)
    }

    func logBiometricPermissionDenied() {
        logEvent(.biometricPermissionDenied)
    }

    func logTabSelected(tabName: String) {
        logEvent(.tabSelected, parameters: [.tabName: tabName])
    }

    func logNotificationOpened(type: String) {
        logEvent(.notificationOpened, parameters: [.type: type])
    }

    func logNotificationSettingChanged(type: String, enabled: Bool) {
        logEvent(.notificationSettingChanged, parameters: [
            .type: type,
            .success: enabled
        ])
    }

    func logFCMTokenRegistered() {
        logEvent(.fcmTokenRegistered)
    }
}
