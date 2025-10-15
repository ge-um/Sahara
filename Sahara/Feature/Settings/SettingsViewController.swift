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

// TODO: - RxDataSource로 Refactor
final class SettingsViewController: UIViewController {
    private let viewModel: SettingsViewModel
    private let disposeBag = DisposeBag()
    private let viewWillAppearRelay = PublishRelay<Void>()

    private let customNavigationBar = CustomNavigationBar()

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.register(SettingsMenuCell.self, forCellWithReuseIdentifier: SettingsMenuCell.identifier)
        collectionView.register(
            SettingsSectionHeader.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: SettingsSectionHeader.identifier
        )
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
        customNavigationBar.hideLeftButton()
    }

    private func configureUI() {
        view.applyGradientWithDots(.pinkToBlue, dotSize: 5, spacing: 32, dotColor: ColorSystem.white)

        view.addSubview(customNavigationBar)
        view.addSubview(collectionView)

        customNavigationBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.horizontalEdges.equalToSuperview()
            make.height.equalTo(54)
        }

        collectionView.snp.makeConstraints { make in
            make.top.equalTo(customNavigationBar.snp.bottom).offset(20)
            make.horizontalEdges.equalToSuperview().inset(20)
            make.bottom.equalTo(view.safeAreaLayoutGuide)
        }
    }

    private func bind() {
        let dataSource = RxCollectionViewSectionedReloadDataSource<SettingsSection>(
            configureCell: { _, collectionView, indexPath, item in
                guard let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: SettingsMenuCell.identifier,
                    for: indexPath
                ) as? SettingsMenuCell else {
                    return UICollectionViewCell()
                }
                cell.configure(with: item)
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

        output.openReleaseNotes
            .drive(with: self) { owner, _ in
                let releaseNotesVC = ReleaseNotesViewController()
                owner.navigationController?.pushViewController(releaseNotesVC, animated: true)
            }
            .disposed(by: disposeBag)
    }

    private func presentMailComposer(to email: String) {
        guard MFMailComposeViewController.canSendMail() else {
            showMailError()
            return
        }

        let mailComposer = MFMailComposeViewController()
        mailComposer.mailComposeDelegate = self
        mailComposer.setToRecipients([email])
        mailComposer.setSubject("")
        mailComposer.setMessageBody("", isHTML: false)

        present(mailComposer, animated: true)
    }

    private func showMailError() {
        let alert = UIAlertController(
            title: NSLocalizedString("settings.mail_error_title", comment: ""),
            message: NSLocalizedString("settings.mail_error_message", comment: ""),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: NSLocalizedString("common.ok", comment: ""), style: .default))
        present(alert, animated: true)
    }
}

extension SettingsViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: 60)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: 40)
    }
}

extension SettingsViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }
}
