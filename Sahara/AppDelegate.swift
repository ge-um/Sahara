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
import UIKit
import RealmSwift
import Kingfisher

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
        RealmService.migrateRealmFileIfNeeded()
        let config = RealmService.createConfiguration()
        Realm.Configuration.defaultConfiguration = config
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
