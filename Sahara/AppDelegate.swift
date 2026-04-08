//
//  AppDelegate.swift
//  Sahara
//
//  Created by 금가경 on 9/26/25.
//

import FirebaseCrashlytics
import FirebaseCore
import FirebaseMessaging
import FirebaseRemoteConfig
import Kingfisher
import RealmSwift
import UIKit
import ZIPFoundation

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    private(set) var cloudSyncService: CloudSyncService?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        #if DEBUG
        Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(false)
        #endif
        AnalyticsService.shared.registerFirstLaunchDateIfNeeded()
        configureRemoteConfig()
        configureRealm()
        configureCloudSync()
        configureKingfisher()

        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self

        UNUserNotificationCenter.current().getNotificationSettings { settings in
            if settings.authorizationStatus == .notDetermined {
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                    AnalyticsService.shared.logNotificationSettingChanged(type: "initial_permission", enabled: granted)
                    if granted {
                        DispatchQueue.main.async {
                            application.registerForRemoteNotifications()
                            NotificationSettings.shared.setServiceNewsEnabledWithoutSubscription(true)
                        }
                    } else {
                        NotificationSettings.shared.setServiceNewsEnabledWithoutSubscription(false)
                    }
                }
            } else if settings.authorizationStatus == .authorized {
                DispatchQueue.main.async {
                    application.registerForRemoteNotifications()
                }
            }
        }

        WidgetDataService.shared.refreshWidgetData()

        return true
    }

    private func configureRemoteConfig() {
        let remoteConfigService = RemoteConfigService.shared
        AnalyticsService.shared.setHasCustomizedThemeProperty(
            BackgroundThemeService.shared.hasCustomizedTheme
        )

        remoteConfigService.fetchAndActivateOnce { success in
            if success {
                BackgroundThemeService.shared.setRemoteConfigService(remoteConfigService)
            } else {
                AnalyticsService.shared.logEvent(.remoteConfigFetchFailed)
            }
        }
    }

    private func configureRealm() {
        if ProcessInfo.processInfo.arguments.contains("-SCREENSHOT_MODE") {
            configureRealmForScreenshots()
            return
        }
        RealmService.migrateRealmFileIfNeeded()
        let config = RealmService.createConfiguration()
        Realm.Configuration.defaultConfiguration = config
    }

    private func configureRealmForScreenshots() {
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory.appendingPathComponent("sahara-screenshots-\(UUID().uuidString)")
        try? fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)

        guard let bundledURL = Bundle.main.url(forResource: "demo_screenshots", withExtension: "sahara") else {
            return
        }

        try? fileManager.unzipItem(at: bundledURL, to: tempDir)

        let realmURL = tempDir.appendingPathComponent("default.realm")
        guard fileManager.fileExists(atPath: realmURL.path) else { return }

        var config = RealmService.createConfiguration()
        config.fileURL = realmURL
        Realm.Configuration.defaultConfiguration = config

        let extractedImagesDir = tempDir.appendingPathComponent("CardImages")
        if fileManager.fileExists(atPath: extractedImagesDir.path) {
            ImageFileService.shared = ImageFileService(baseDirectory: extractedImagesDir)
        }

        localizeCardMemos(config: config)
    }

    private func localizeCardMemos(config: Realm.Configuration) {
        let lang = Locale.current.language.languageCode?.identifier ?? "ko"
        guard lang != "ko" else { return }

        let memoTranslations: [String: [String: String]] = [
            "en": [
                "귀여운 고양이를 만났당 🥹": "Met a cute cat today 🥹",
                "메모를 입력해요": "Write a memo"
            ],
            "ja": [
                "귀여운 고양이를 만났당 🥹": "かわいい猫に出会った 🥹",
                "메모를 입력해요": "メモを入力"
            ],
            "zh": [
                "귀여운 고양이를 만났당 🥹": "遇到了一只可爱的猫咪 🥹",
                "메모를 입력해요": "输入备注"
            ]
        ]

        // 언어별 도시 좌표 (위치가 있는 카드를 해당 국가 도시로 이동)
        let cityCoords: [String: (lat: Double, lon: Double)] = [
            "en": (40.7580, -73.9855),  // 뉴욕 타임스퀘어
            "ja": (35.6595, 139.7004),  // 도쿄 시부야
            "zh": (31.2304, 121.4737)   // 상하이 와이탄
        ]

        let key = lang == "zh" ? "zh" : lang
        guard let translations = memoTranslations[key] else { return }

        guard let realm = try? Realm(configuration: config) else { return }
        try? realm.write {
            for card in realm.objects(Card.self) {
                // 메모 번역
                if let memo = card.memo, !memo.isEmpty, let translated = translations[memo] {
                    card.memo = translated
                }
                // 좌표를 해당 국가 도시로 이동
                if let city = cityCoords[key], card.latitude != nil {
                    // 카드마다 약간의 분산 (같은 좌표에 몰리지 않도록)
                    let jitter = Double(card.date.hashValue % 100) * 0.001
                    card.latitude = city.lat + jitter
                    card.longitude = city.lon + jitter
                }
            }
        }
    }

    private func configureCloudSync() {
        let syncService = CloudSyncService(
            realmService: RealmService.shared,
            imageFileService: ImageFileService.shared
        )
        self.cloudSyncService = syncService
        RealmService.shared.syncService = syncService

        if syncService.isEnabled {
            syncService.startSync()
        }
    }

    private func configureKingfisher() {
        let cache = ImageCache.default
        cache.memoryStorage.config.totalCostLimit = 100 * 1024 * 1024
        cache.memoryStorage.config.countLimit = 100
        cache.diskStorage.config.sizeLimit = 500 * 1024 * 1024
    }

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        let type = userInfo["type"] as? String ?? "unknown"

        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let sceneDelegate = scene.delegate as? SceneDelegate {
            sceneDelegate.handleNotification(type: type, userInfo: userInfo)
        }

        completionHandler()
    }
}

extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
      let dataDict: [String: String] = ["token": fcmToken ?? ""]
      NotificationCenter.default.post(
        name: Notification.Name("FCMToken"),
        object: nil,
        userInfo: dataDict
      )

      if NotificationSettings.shared.isServiceNewsEnabled {
          NotificationSettings.shared.subscribeToServiceNews()
      }
    }
}
