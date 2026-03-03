//
//  SceneDelegate.swift
//  Sahara
//
//  Created by 금가경 on 9/26/25.
//

import MessageUI
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {

        guard let scene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: scene)

        if RealmManager.validateRealm() != nil {
            let errorVC = UIViewController()
            errorVC.view.backgroundColor = .white
            window?.rootViewController = errorVC
            window?.makeKeyAndVisible()
            showRealmFailureAlert(on: errorVC)
            return
        }

        let mainTabBarController = MainTabBarController()
        window?.rootViewController = mainTabBarController

        window?.makeKeyAndVisible()
    }

    private func showRealmFailureAlert(on viewController: UIViewController) {
        let alert = UIAlertController(
            title: NSLocalizedString("realm_error.title", comment: ""),
            message: NSLocalizedString("realm_error.message", comment: ""),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(
            title: NSLocalizedString("realm_error.contact", comment: ""),
            style: .default
        ) { [weak viewController] _ in
            guard let viewController = viewController else { return }
            self.presentRealmErrorMail(on: viewController)
        })
        alert.addAction(UIAlertAction(
            title: NSLocalizedString("common.ok", comment: ""),
            style: .cancel
        ))
        viewController.present(alert, animated: true)
    }

    private func presentRealmErrorMail(on viewController: UIViewController) {
        guard MFMailComposeViewController.canSendMail() else {
            UIPasteboard.general.string = "gageum0@gmail.com"
            let fallback = UIAlertController(
                title: NSLocalizedString("settings.mail_error_title", comment: ""),
                message: NSLocalizedString("realm_error.email_copied", comment: ""),
                preferredStyle: .alert
            )
            fallback.addAction(UIAlertAction(title: NSLocalizedString("common.ok", comment: ""), style: .default))
            viewController.present(fallback, animated: true)
            return
        }

        let mailComposer = MFMailComposeViewController()
        mailComposer.mailComposeDelegate = self
        mailComposer.setToRecipients(["gageum0@gmail.com"])
        mailComposer.setSubject(NSLocalizedString("realm_error.mail_subject", comment: ""))

        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let iosVersion = UIDevice.current.systemVersion
        let body = """
        \(NSLocalizedString("realm_error.mail_body", comment: ""))

        ---
        \(NSLocalizedString("settings.app_version", comment: "")): \(appVersion)
        \(NSLocalizedString("settings.ios_version", comment: "")): \(iosVersion)
        """
        mailComposer.setMessageBody(body, isHTML: false)

        viewController.present(mailComposer, animated: true)
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

extension SceneDelegate: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }
}
