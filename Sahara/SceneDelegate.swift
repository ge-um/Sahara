//
//  SceneDelegate.swift
//  Sahara
//
//  Created by 금가경 on 9/26/25.
//

import MessageUI
import RealmSwift
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {

        guard let scene = (scene as? UIWindowScene) else { return }

        configureWindowSize(for: scene)

        window = UIWindow(windowScene: scene)

        if RealmService.validateRealm() != nil {
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

        if let url = connectionOptions.urlContexts.first?.url {
            if url.scheme == AppGroupContainer.widgetURLScheme {
                handleWidgetDeepLink(url: url)
            } else {
                handleBackupFileImport(url: url)
            }
        }
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else { return }

        if url.scheme == AppGroupContainer.widgetURLScheme {
            handleWidgetDeepLink(url: url)
        } else {
            handleBackupFileImport(url: url)
        }
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
        let email = "gageum0@gmail.com"
        let subject = NSLocalizedString("realm_error.mail_subject", comment: "")
        let body = generateRealmErrorMailBody()

        #if targetEnvironment(macCatalyst)
        openMailtoURL(to: email, subject: subject, body: body, fallbackPresenter: viewController)
        #else
        guard MFMailComposeViewController.canSendMail() else {
            copyEmailFallback(email: email, presenter: viewController)
            return
        }

        let mailComposer = MFMailComposeViewController()
        mailComposer.mailComposeDelegate = self
        mailComposer.setToRecipients([email])
        mailComposer.setSubject(subject)
        mailComposer.setMessageBody(body, isHTML: false)

        viewController.present(mailComposer, animated: true)
        #endif
    }

    private func generateRealmErrorMailBody() -> String {
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let osVersionLabel: String
        let osVersion: String

        #if targetEnvironment(macCatalyst)
        osVersionLabel = NSLocalizedString("settings.macos_version", comment: "")
        let version = ProcessInfo.processInfo.operatingSystemVersion
        osVersion = "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
        #else
        osVersionLabel = NSLocalizedString("settings.ios_version", comment: "")
        osVersion = UIDevice.current.systemVersion
        #endif

        return """
        \(NSLocalizedString("realm_error.mail_body", comment: ""))

        ---
        \(NSLocalizedString("settings.app_version", comment: "")): \(appVersion)
        \(osVersionLabel): \(osVersion)
        """
    }

    private func openMailtoURL(to email: String, subject: String, body: String, fallbackPresenter: UIViewController) {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = email
        components.queryItems = [
            URLQueryItem(name: "subject", value: subject),
            URLQueryItem(name: "body", value: body)
        ]

        guard let url = components.url else {
            copyEmailFallback(email: email, presenter: fallbackPresenter)
            return
        }

        UIApplication.shared.open(url) { [weak self] success in
            if !success {
                self?.copyEmailFallback(email: email, presenter: fallbackPresenter)
            }
        }
    }

    private func copyEmailFallback(email: String, presenter: UIViewController) {
        UIPasteboard.general.string = email
        let alert = UIAlertController(
            title: NSLocalizedString("settings.mail_error_title", comment: ""),
            message: NSLocalizedString("realm_error.email_copied", comment: ""),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: NSLocalizedString("common.ok", comment: ""), style: .default))
        presenter.present(alert, animated: true)
    }

    private func configureWindowSize(for scene: UIWindowScene) {
        #if targetEnvironment(macCatalyst)
        scene.title = "Sahara"
        scene.sizeRestrictions?.minimumSize = CGSize(width: 600, height: 500)
        scene.sizeRestrictions?.maximumSize = CGSize(width: 1200, height: 900)
        #endif
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        CardPostProcessor.shared.processUntaggedCards()

        if let syncService = CloudSyncService.current,
           syncService.isEnabled {
            syncService.fetchChangesIfNeeded()
        }
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        UNUserNotificationCenter.current().setBadgeCount(0)
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        WidgetDataService.shared.refreshWidgetData()
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
    }

    private func handleWidgetDeepLink(url: URL) {
        guard url.host == "card",
              let cardIdString = url.pathComponents.last,
              let objectId = try? ObjectId(string: cardIdString) else { return }

        guard let tabBarController = window?.rootViewController as? MainTabBarController else { return }
        tabBarController.selectedIndex = 0

        guard let navController = tabBarController.selectedViewController as? UINavigationController else { return }
        navController.popToRootViewController(animated: false)

        let detailVC = CardDetailViewController(cardId: objectId)
        navController.pushViewController(detailVC, animated: true)
    }

    private func handleBackupFileImport(url: URL) {
        do {
            let (tempURL, metadata) = try BackupService.shared.prepareForImport(from: url)
            showImportConfirmation(metadata: metadata, fileURL: tempURL)
        } catch {
            showImportError(error)
        }
    }

    private func showImportConfirmation(metadata: BackupMetadata, fileURL: URL) {
        guard let rootVC = window?.rootViewController else { return }

        let title = NSLocalizedString("backup.confirm_import_title", comment: "")
        let message = String(
            format: NSLocalizedString("backup.confirm_import_message", comment: ""),
            metadata.cardCount
        )

        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(
            title: NSLocalizedString("backup.confirm_import_action", comment: ""),
            style: .destructive
        ) { _ in
            self.performImport(from: fileURL)
        })
        alert.addAction(UIAlertAction(
            title: NSLocalizedString("common.cancel", comment: ""),
            style: .cancel
        ))

        let presenter = rootVC.presentedViewController ?? rootVC
        presenter.present(alert, animated: true)
    }

    private func performImport(from url: URL) {
        guard let rootVC = window?.rootViewController else { return }

        let progressAlert = UIAlertController.progressAlert(
            title: NSLocalizedString("backup.importing", comment: "")
        )

        let presenter = rootVC.presentedViewController ?? rootVC
        presenter.present(progressAlert.alert, animated: true)

        CloudSyncService.current?.stopSyncForBackupRestore()

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                try BackupService.shared.importBackup(from: url) { progress in
                    DispatchQueue.main.async {
                        progressAlert.progressView.setProgress(Float(progress), animated: true)
                    }
                }
                DispatchQueue.main.async {
                    WidgetDataService.shared.refreshWidgetData()
                    if CloudSyncService.current?.isEnabled == true {
                        CloudSyncService.current?.restartSyncAfterBackupRestore()
                    }
                    progressAlert.alert.dismiss(animated: true) {
                        self?.showImportSuccess()
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    if CloudSyncService.current?.isEnabled == true {
                        CloudSyncService.current?.restartSyncAfterBackupRestore()
                    }
                    progressAlert.alert.dismiss(animated: true) {
                        self?.showImportError(error)
                    }
                }
            }
        }
    }

    private func showImportSuccess() {
        guard let rootVC = window?.rootViewController else { return }
        let alert = UIAlertController(
            title: NSLocalizedString("backup.import_success", comment: ""),
            message: nil,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(
            title: NSLocalizedString("common.ok", comment: ""),
            style: .default
        ))
        rootVC.present(alert, animated: true)
    }

    private func showImportError(_ error: Error) {
        guard let rootVC = window?.rootViewController else { return }
        let presenter = rootVC.presentedViewController ?? rootVC
        let alert = UIAlertController(
            title: NSLocalizedString("backup.import_failed", comment: ""),
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: NSLocalizedString("common.ok", comment: ""), style: .default))
        presenter.present(alert, animated: true)
    }

    func handleNotification(type: String, userInfo: [AnyHashable: Any]) {
        guard let tabBarController = window?.rootViewController as? MainTabBarController else { return }

        switch type {
        case "weekly_report", "monthly_report":
            tabBarController.selectedIndex = 2
            AnalyticsService.shared.logNotificationOpened(type: type)

        case "memory_reminder", "milestone":
            tabBarController.selectedIndex = 0
            AnalyticsService.shared.logNotificationOpened(type: type)

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
