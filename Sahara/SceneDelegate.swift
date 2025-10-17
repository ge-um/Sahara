//
//  SceneDelegate.swift
//  Sahara
//
//  Created by 금가경 on 9/26/25.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {

        guard let scene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: scene)

        if LanguageManager.shared.hasSelectedLanguage {
            let mainTabBarController = MainTabBarController()
            window?.rootViewController = mainTabBarController
        } else {
            if LanguageManager.shared.isSupportedSystemLanguage {
                LanguageManager.shared.setLanguage(LanguageManager.shared.systemLanguage)
                let mainTabBarController = MainTabBarController()
                window?.rootViewController = mainTabBarController
            } else {
                let languageVC = InitialLanguageSelectionViewController()
                languageVC.onLanguageSelected = { [weak self] in
                    let mainTabBarController = MainTabBarController()
                    self?.window?.rootViewController = mainTabBarController
                }
                window?.rootViewController = languageVC
            }
        }

        window?.makeKeyAndVisible()
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        UIApplication.shared.applicationIconBadgeNumber = 0
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
    }

    func handleNotification(type: String, userInfo: [AnyHashable: Any]) {
        guard let tabBarController = window?.rootViewController as? MainTabBarController else { return }

        switch type {
        case "weekly_report", "monthly_report":
            tabBarController.selectedIndex = 2
            AnalyticsManager.shared.logNotificationOpened(type: type)

        case "memory_reminder", "milestone":
            tabBarController.selectedIndex = 0
            AnalyticsManager.shared.logNotificationOpened(type: type)

        default:
            break
        }
    }
}

