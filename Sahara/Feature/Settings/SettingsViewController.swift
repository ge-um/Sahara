//
//  SettingsViewController.swift
//  Sahara
//
//  Created by 금가경 on 1/11/25.
//

import MessageUI
import RxCocoa
import RxDataSources
import RxSwift
import SnapKit
import UIKit
import UniformTypeIdentifiers

final class SettingsViewController: UIViewController {
    private let viewModel: SettingsViewModel
    private let disposeBag = DisposeBag()
    private let viewWillAppearRelay = PublishRelay<Void>()

    private let customNavigationBar = CustomNavigationBar()

    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: SettingsGroupedLayout())
        collectionView.backgroundColor = .clear
        collectionView.register(SettingsMenuCell.self, forCellWithReuseIdentifier: SettingsMenuCell.identifier)
        collectionView.register(
            SettingsSectionHeader.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: SettingsSectionHeader.identifier
        )
        collectionView.showsVerticalScrollIndicator = false
        collectionView.contentInset.bottom = 80
        collectionView.delegate = self
        return collectionView
    }()

    init(viewModel: SettingsViewModel = SettingsViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        setupCustomNavigationBar()
        configureUI()
        bind()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewWillAppearRelay.accept(())
    }

    private func setupCustomNavigationBar() {
        customNavigationBar.configure(title: NSLocalizedString("settings.title", comment: ""))
        updateLeftButtonForCurrentMode()
    }

    private func updateLeftButtonForCurrentMode() {
        if let toggler = navigationController?.parent as? SidebarToggleable, toggler.isSidebarMode {
            customNavigationBar.showLeftButton()
            customNavigationBar.setLeftButtonImage(UIImage(systemName: "sidebar.leading"))
            customNavigationBar.onLeftButtonTapped = { [weak toggler] in
                toggler?.toggleSidebar()
            }
        } else {
            customNavigationBar.hideLeftButton()
        }
    }

    private func configureUI() {
        view.bindBackgroundTheme(disposedBy: disposeBag)

        view.addSubview(customNavigationBar)
        view.addSubview(collectionView)

        customNavigationBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.horizontalEdges.equalToSuperview()
            make.height.equalTo(54)
        }

        collectionView.snp.makeConstraints { make in
            make.top.equalTo(customNavigationBar.snp.bottom).offset(20)
            make.centerX.equalToSuperview()
            make.width.lessThanOrEqualTo(600)
            make.horizontalEdges.equalToSuperview().inset(20).priority(.medium)
            make.bottom.equalTo(view.safeAreaLayoutGuide)
        }
    }

    private func bind() {
        let dataSource = RxCollectionViewSectionedReloadDataSource<SettingsSection>(
            configureCell: { [weak self] dataSource, collectionView, indexPath, item in
                guard let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: SettingsMenuCell.identifier,
                    for: indexPath
                ) as? SettingsMenuCell else {
                    return UICollectionViewCell()
                }
                cell.configure(with: item)

                cell.onToggleChanged = { [weak self] isOn in
                    self?.handleToggleChanged(for: item, isOn: isOn)
                }

                return cell
            },
            configureSupplementaryView: { dataSource, collectionView, kind, indexPath in
                guard kind == UICollectionView.elementKindSectionHeader else {
                    return UICollectionReusableView()
                }

                guard let header = collectionView.dequeueReusableSupplementaryView(
                    ofKind: kind,
                    withReuseIdentifier: SettingsSectionHeader.identifier,
                    for: indexPath
                ) as? SettingsSectionHeader else {
                    return UICollectionReusableView()
                }

                let section = dataSource[indexPath.section]
                header.configure(with: section.title)
                return header
            }
        )

        let itemSelected = collectionView.rx.modelSelected(SettingsMenuItem.self)
            .filter { $0.isSelectable }

        let input = SettingsViewModel.Input(
            viewWillAppear: viewWillAppearRelay.asObservable(),
            itemSelected: itemSelected
        )

        let output = viewModel.transform(input: input)

        output.sections
            .drive(collectionView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)

        output.openMailComposer
            .drive(with: self) { owner, email in
                owner.presentMailComposer(to: email)
            }
            .disposed(by: disposeBag)

        output.openLanguageSelection
            .drive(with: self) { owner, _ in
                let languageVC = LanguageSelectionViewController()
                owner.navigationController?.pushViewController(languageVC, animated: true)
            }
            .disposed(by: disposeBag)

        output.openBackgroundTheme
            .drive(with: self) { owner, _ in
                AnalyticsService.shared.logThemeSettingsViewed()
                let bgVC = BackgroundThemeViewController()
                owner.navigationController?.pushViewController(bgVC, animated: true)
            }
            .disposed(by: disposeBag)

        output.openReleaseNotes
            .drive(with: self) { owner, _ in
                let releaseNotesVC = ReleaseNotesViewController()
                owner.navigationController?.pushViewController(releaseNotesVC, animated: true)
            }
            .disposed(by: disposeBag)

        output.exportPhotos
            .drive(with: self) { owner, _ in
                owner.performExport(using: BackupService.shared.exportPhotosOnly)
            }
            .disposed(by: disposeBag)

        output.exportBackup
            .drive(with: self) { owner, _ in
                owner.performExport(using: BackupService.shared.exportBackup)
            }
            .disposed(by: disposeBag)

        output.importBackup
            .drive(with: self) { owner, _ in
                owner.presentDocumentPicker()
            }
            .disposed(by: disposeBag)
    }

    private func presentMailComposer(to email: String) {
        #if targetEnvironment(macCatalyst)
        openMailtoURL(to: email, subject: NSLocalizedString("settings.inquiry_subject", comment: ""), body: generateEmailBody())
        #else
        guard MFMailComposeViewController.canSendMail() else {
            copyEmailFallback(email: email)
            return
        }

        let mailComposer = MFMailComposeViewController()
        mailComposer.mailComposeDelegate = self
        mailComposer.setToRecipients([email])
        mailComposer.setSubject(NSLocalizedString("settings.inquiry_subject", comment: ""))
        mailComposer.setMessageBody(generateEmailBody(), isHTML: false)

        present(mailComposer, animated: true)
        #endif
    }

    private func openMailtoURL(to email: String, subject: String, body: String) {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = email
        components.queryItems = [
            URLQueryItem(name: "subject", value: subject),
            URLQueryItem(name: "body", value: body)
        ]

        guard let url = components.url else {
            copyEmailFallback(email: email)
            return
        }

        UIApplication.shared.open(url) { [weak self] success in
            if !success {
                self?.copyEmailFallback(email: email)
            }
        }
    }

    private func copyEmailFallback(email: String) {
        UIPasteboard.general.string = email
        let alert = UIAlertController(
            title: NSLocalizedString("settings.mail_error_title", comment: ""),
            message: NSLocalizedString("realm_error.email_copied", comment: ""),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: NSLocalizedString("common.ok", comment: ""), style: .default))
        present(alert, animated: true)
    }

    private func generateEmailBody() -> String {
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let osVersionLabel: String
        let osVersion: String
        let deviceModel = DeviceInfo.displayName

        #if targetEnvironment(macCatalyst)
        osVersionLabel = NSLocalizedString("settings.macos_version", comment: "")
        let version = ProcessInfo.processInfo.operatingSystemVersion
        osVersion = "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
        #else
        osVersionLabel = NSLocalizedString("settings.ios_version", comment: "")
        osVersion = UIDevice.current.systemVersion
        #endif

        return """
        \(NSLocalizedString("settings.inquiry_message_placeholder", comment: ""))

        ---
        \(NSLocalizedString("settings.device_info_title", comment: ""))
        - \(NSLocalizedString("settings.app_version", comment: "")): \(appVersion)
        - \(osVersionLabel): \(osVersion)
        - \(NSLocalizedString("settings.device_model", comment: "")): \(deviceModel)
        """
    }

    private func handleToggleChanged(for item: SettingsMenuItem, isOn: Bool) {
        if case .serviceNews = item {
            if isOn {
                NotificationSettings.shared.checkSystemNotificationPermission { [weak self] isAuthorized in
                    if isAuthorized {
                        NotificationSettings.shared.isServiceNewsEnabled = true
                        AnalyticsService.shared.logNotificationSettingChanged(type: "service_news", enabled: true)
                    } else {
                        NotificationSettings.shared.isServiceNewsEnabled = false
                        self?.showSettingsAlert()
                        self?.viewWillAppearRelay.accept(())
                    }
                }
            } else {
                NotificationSettings.shared.isServiceNewsEnabled = false
                AnalyticsService.shared.logNotificationSettingChanged(type: "service_news", enabled: false)
            }
        }

        if case .cloudSync = item {
            if isOn {
                showCloudSyncConfirmation()
            } else {
                CloudSyncService.current?.stopSync()
                viewWillAppearRelay.accept(())
            }
        }
    }

    // MARK: - Cloud Sync

    private func showCloudSyncConfirmation() {
        let alert = UIAlertController(
            title: NSLocalizedString("sync.confirm_title", comment: ""),
            message: NSLocalizedString("sync.confirm_message", comment: ""),
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(
            title: NSLocalizedString("common.ok", comment: ""),
            style: .default
        ) { [weak self] _ in
            self?.startCloudSync()
        })

        alert.addAction(UIAlertAction(
            title: NSLocalizedString("common.cancel", comment: ""),
            style: .cancel
        ) { [weak self] _ in
            self?.viewWillAppearRelay.accept(())
        })

        present(alert, animated: true)
    }

    private func startCloudSync() {
        guard let syncService = CloudSyncService.current else { return }

        syncService.checkAccountStatus { [weak self] isAvailable in
            guard let self else { return }

            if isAvailable {
                syncService.startSync()
                syncService.triggerFullSync()
                self.viewWillAppearRelay.accept(())
            } else {
                self.showCloudAccountUnavailableAlert()
                self.viewWillAppearRelay.accept(())
            }
        }
    }

    private func showCloudAccountUnavailableAlert() {
        let alert = UIAlertController(
            title: NSLocalizedString("sync.account_unavailable_title", comment: ""),
            message: NSLocalizedString("sync.account_unavailable_message", comment: ""),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(
            title: NSLocalizedString("common.ok", comment: ""),
            style: .default
        ))
        present(alert, animated: true)
    }

    // MARK: - Backup & Restore

    private func performExport(using operation: @escaping (@escaping (Double) -> Void) throws -> URL) {
        let progressAlert = createProgressAlert(title: NSLocalizedString("backup.exporting", comment: ""))
        present(progressAlert.alert, animated: true)

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                let url = try operation { progress in
                    DispatchQueue.main.async {
                        progressAlert.progressView.setProgress(Float(progress), animated: true)
                    }
                }
                DispatchQueue.main.async {
                    progressAlert.alert.dismiss(animated: true) {
                        self?.presentShareSheet(for: url)
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    progressAlert.alert.dismiss(animated: true) {
                        self?.showBackupError(title: NSLocalizedString("backup.export_failed", comment: ""), error: error)
                    }
                }
            }
        }
    }

    private func presentDocumentPicker() {
        let saharaType = UTType("com.miya.sahara.backup") ?? .data
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [saharaType])
        picker.delegate = self
        picker.allowsMultipleSelection = false
        present(picker, animated: true)
    }

    private func createProgressAlert(title: String) -> (alert: UIAlertController, progressView: UIProgressView) {
        UIAlertController.progressAlert(title: title)
    }

    private func presentShareSheet(for url: URL) {
        #if targetEnvironment(macCatalyst)
        let picker = UIDocumentPickerViewController(forExporting: [url])
        present(picker, animated: true)
        #else
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
        }
        present(activityVC, animated: true)
        #endif
    }

    private func showBackupError(title: String, error: Error) {
        let alert = UIAlertController(
            title: title,
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: NSLocalizedString("common.ok", comment: ""), style: .default))
        present(alert, animated: true)
    }

    private func showSettingsAlert() {
        let alert = UIAlertController(
            title: NSLocalizedString("settings.notification_denied_title", comment: ""),
            message: NSLocalizedString("settings.notification_denied_message", comment: ""),
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(
            title: NSLocalizedString("media_selection.go_to_settings", comment: ""),
            style: .default
        ) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        })

        alert.addAction(UIAlertAction(
            title: NSLocalizedString("common.cancel", comment: ""),
            style: .cancel
        ))

        present(alert, animated: true)
    }
}

extension SettingsViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: 60)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: 32)
    }
}

extension SettingsViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }
}

extension SettingsViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }

        do {
            let (tempURL, metadata) = try BackupService.shared.prepareForImport(from: url)
            showImportConfirmation(metadata: metadata, fileURL: tempURL)
        } catch {
            showBackupError(title: NSLocalizedString("backup.import_failed", comment: ""), error: error)
        }
    }

    private func showImportConfirmation(metadata: BackupMetadata, fileURL: URL) {
        let title = NSLocalizedString("backup.confirm_import_title", comment: "")
        let message = String(
            format: NSLocalizedString("backup.confirm_import_message", comment: ""),
            metadata.cardCount
        )

        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(
            title: NSLocalizedString("backup.confirm_import_action", comment: ""),
            style: .destructive
        ) { [weak self] _ in
            self?.performImport(from: fileURL)
        })
        alert.addAction(UIAlertAction(
            title: NSLocalizedString("common.cancel", comment: ""),
            style: .cancel
        ))
        present(alert, animated: true)
    }

    private func performImport(from url: URL) {
        let progressAlert = createProgressAlert(title: NSLocalizedString("backup.importing", comment: ""))
        present(progressAlert.alert, animated: true)

        CloudSyncService.current?.stopSyncForBackupRestore()

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                try BackupService.shared.importBackup(from: url) { progress in
                    DispatchQueue.main.async {
                        progressAlert.progressView.setProgress(Float(progress), animated: true)
                    }
                }
                DispatchQueue.main.async {
                    if CloudSyncService.current?.isEnabled == true {
                        CloudSyncService.current?.restartSyncAfterBackupRestore()
                    }
                    progressAlert.alert.dismiss(animated: true) {
                        guard let self else { return }
                        let alert = UIAlertController(
                            title: NSLocalizedString("backup.import_success", comment: ""),
                            message: nil,
                            preferredStyle: .alert
                        )
                        alert.addAction(UIAlertAction(
                            title: NSLocalizedString("common.ok", comment: ""),
                            style: .default
                        ))
                        self.present(alert, animated: true)
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    if CloudSyncService.current?.isEnabled == true {
                        CloudSyncService.current?.restartSyncAfterBackupRestore()
                    }
                    progressAlert.alert.dismiss(animated: true) {
                        self?.showBackupError(
                            title: NSLocalizedString("backup.import_failed", comment: ""),
                            error: error
                        )
                    }
                }
            }
        }
    }
}

extension UIAlertController {
    static func progressAlert(title: String) -> (alert: UIAlertController, progressView: UIProgressView) {
        let alert = UIAlertController(title: title, message: "\n\n", preferredStyle: .alert)
        let progressView = UIProgressView(progressViewStyle: .default)
        alert.view.addSubview(progressView)
        progressView.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview().inset(20)
            make.bottom.equalToSuperview().inset(45)
        }
        return (alert, progressView)
    }
}

// MARK: - SidebarModeObserver

extension SettingsViewController: SidebarModeObserver {
    func sidebarModeDidChange() {
        updateLeftButtonForCurrentMode()
    }
}
