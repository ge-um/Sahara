//
//  CardDetailViewController.swift
//  Sahara
//
//  Created by 금가경 on 9/26/25.
//

import RealmSwift
import RxCocoa
import RxSwift
import SnapKit
import UIKit

final class CardDetailViewController: UIViewController {
    private let viewModel: CardDetailViewModel
    private let photoCardViewModel: PhotoCardViewModel
    private let realmManager: RealmServiceProtocol
    private let disposeBag = DisposeBag()
    private let sourceType: EditSourceType

    private let viewDidLoadRelay = PublishRelay<Void>()
    private let deleteConfirmedRelay = PublishRelay<Void>()

    private let customNavigationBar = CustomNavigationBar()

    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.backgroundColor = .clear
        return scrollView
    }()

    private let contentView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()

    private lazy var photoCardView: PhotoCardView = {
        let availableWidth = view.bounds.width - 64
        let cardWidth = UIDevice.current.userInterfaceIdiom == .phone ? availableWidth : min(availableWidth, 500)
        return PhotoCardView(cardWidth: cardWidth)
    }()

    private let buttonContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()

    private lazy var saveButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .white
        button.layer.cornerRadius = 35
        button.clipsToBounds = true

        let font = FontSystem.galmuriMono(size: 12)
        let title = NSLocalizedString("common.save", comment: "")
        button.setAttributedTitle(title.attributedString(font: font, letterSpacing: -6, color: .black), for: .normal)

        return button
    }()

    private lazy var shareButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .white
        button.layer.cornerRadius = 35
        button.clipsToBounds = true

        let font = FontSystem.galmuriMono(size: 12)
        let title = NSLocalizedString("common.share", comment: "")
        button.setAttributedTitle(title.attributedString(font: font, letterSpacing: -6, color: .black), for: .normal)

        return button
    }()

    private let widgetToggleButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.cornerStyle = .capsule
        config.buttonSize = .small
        config.image = UIImage(systemName: "plus")
        config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 13)
        config.imagePadding = 6
        config.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20)
        config.baseForegroundColor = UIColor(red: 142/255, green: 142/255, blue: 147/255, alpha: 1)
        config.title = NSLocalizedString("widget.add_to_widget", comment: "")
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = FontSystem.galmuriMono(size: 12)
            return outgoing
        }
        let button = UIButton(configuration: config)
        button.clipsToBounds = true
        button.backgroundColor = UIColor(red: 242/255, green: 242/255, blue: 247/255, alpha: 1)
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor(red: 209/255, green: 209/255, blue: 214/255, alpha: 1).cgColor
        return button
    }()

    init(cardId: ObjectId, sourceType: EditSourceType = .dateView, realmManager: RealmServiceProtocol = RealmService.shared) {
        self.realmManager = realmManager
        self.viewModel = CardDetailViewModel(cardId: cardId, realmManager: realmManager)
        self.photoCardViewModel = PhotoCardViewModel(cardId: cardId, realmManager: realmManager)
        self.sourceType = sourceType
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
        viewDidLoadRelay.accept(())
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewDidLoadRelay.accept(())
    }

    private func setupCustomNavigationBar() {
        customNavigationBar.configure(title: NSLocalizedString("card_detail.title", comment: ""))

        if navigationController != nil && presentingViewController == nil {
            customNavigationBar.setLeftButtonImage(UIImage(named: "chevronLeft"))
            customNavigationBar.onLeftButtonTapped = { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            }
        } else {
            customNavigationBar.setLeftButtonImage(UIImage(systemName: "xmark"))
            customNavigationBar.onLeftButtonTapped = { [weak self] in
                self?.dismiss(animated: true)
            }
        }

        customNavigationBar.addRightButton(image: UIImage(named: "editBox"), tintColor: .black) { [weak self] in
            self?.openEditView()
        }
    }

    private func configureUI() {
        view.bindBackgroundTheme(disposedBy: disposeBag)

        view.addSubview(customNavigationBar)
        view.addSubview(scrollView)

        scrollView.addSubview(contentView)
        contentView.addSubview(photoCardView)
        contentView.addSubview(buttonContainerView)

        buttonContainerView.addSubview(saveButton)
        buttonContainerView.addSubview(shareButton)
        contentView.addSubview(widgetToggleButton)

        customNavigationBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.horizontalEdges.equalToSuperview()
            make.height.equalTo(54)
        }

        scrollView.snp.makeConstraints { make in
            make.top.equalTo(customNavigationBar.snp.bottom)
            make.horizontalEdges.bottom.equalToSuperview()
        }

        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(scrollView.snp.width)
        }

        photoCardView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(32)
            if UIDevice.current.userInterfaceIdiom == .phone {
                make.horizontalEdges.equalToSuperview().inset(32)
            } else {
                make.centerX.equalToSuperview()
                make.width.lessThanOrEqualTo(500)
                make.horizontalEdges.equalToSuperview().inset(32).priority(.medium)
            }
        }

        buttonContainerView.snp.makeConstraints { make in
            make.top.equalTo(photoCardView.snp.bottom).offset(32)
            make.centerX.equalToSuperview()
            make.height.equalTo(70)
        }

        widgetToggleButton.snp.makeConstraints { make in
            make.top.equalTo(buttonContainerView.snp.bottom).offset(16)
            make.centerX.equalTo(buttonContainerView)
            make.bottom.equalToSuperview().offset(-88)
        }


        saveButton.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.centerY.equalToSuperview()
            make.width.height.equalTo(70)
        }

        shareButton.snp.makeConstraints { make in
            make.leading.equalTo(saveButton.snp.trailing).offset(12)
            make.trailing.equalToSuperview()
            make.centerY.equalToSuperview()
            make.width.height.equalTo(70)
        }
    }

    private func showDeleteAlert() {
        AlertUtility.showDeleteConfirmation(on: self) { [weak self] in
            self?.deleteConfirmedRelay.accept(())
        }
    }

    private func openEditView() {
        guard realmManager.fetchObject(Card.self, forPrimaryKey: viewModel.cardId) != nil else { return }
        let editViewModel = CardInfoViewModel(cardToEdit: viewModel.cardId, sourceType: sourceType)
        let coordinator = CardInfoCoordinator(parentViewController: self)
        let editVC = CardInfoViewController(viewModel: editViewModel, coordinator: coordinator)
        coordinator.cardInfoViewController = editVC
        let navController = UINavigationController(rootViewController: editVC)
        navController.modalPresentationStyle = .fullScreen
        present(navController, animated: true)
    }

    private func bindSaveOutput(_ output: CardDetailViewModel.Output) {
        #if targetEnvironment(macCatalyst)
        output.saveFileURL
            .drive(with: self) { owner, url in
                let picker = UIDocumentPickerViewController(forExporting: [url])
                owner.present(picker, animated: true)
            }
            .disposed(by: disposeBag)
        #else
        output.saveResult
            .drive(with: self) { owner, result in
                switch result {
                case .success:
                    let message = NSLocalizedString("photo_detail.save_success_message", comment: "")
                    owner.showToast(message: message)
                case .failure(let error):
                    owner.showToast(message: error.localizedDescription)
                }
            }
            .disposed(by: disposeBag)
        #endif
    }

    private func bind() {
        photoCardView.deleteButtonTappedRelay
            .bind(with: self) { owner, _ in
                owner.showDeleteAlert()
            }
            .disposed(by: disposeBag)

        let photoCardInput = PhotoCardViewModel.Input(
            viewDidLoad: viewDidLoadRelay.asObservable(),
            swipeLeft: photoCardView.swipeLeftRelay.asObservable(),
            swipeRight: photoCardView.swipeRightRelay.asObservable()
        )

        let photoCardOutput = photoCardViewModel.transform(input: photoCardInput)

        photoCardView.bind(
            photoImage: photoCardOutput.photoImage,
            dateText: photoCardOutput.dateText,
            locationText: photoCardOutput.locationText,
            memoText: photoCardOutput.memoText,
            shouldFlipToBack: photoCardOutput.shouldFlipToBack.asObservable(),
            shouldFlipToFront: photoCardOutput.shouldFlipToFront.asObservable()
        )

        let input = CardDetailViewModel.Input(
            viewDidLoad: viewDidLoadRelay.asObservable(),
            saveButtonTapped: saveButton.rx.tap.asObservable(),
            shareButtonTapped: shareButton.rx.tap.asObservable(),
            deleteConfirmed: deleteConfirmedRelay.asObservable(),
            widgetToggleTapped: widgetToggleButton.rx.tap.asObservable()
        )

        let output = viewModel.transform(input: input)

        bindSaveOutput(output)

        output.shareImage
            .drive(with: self) { owner, image in
                let itemSource = ShareActivityItemSource(image: image)
                let activityVC = UIActivityViewController(activityItems: [itemSource], applicationActivities: nil)
                activityVC.popoverPresentationController?.sourceView = owner.shareButton
                activityVC.popoverPresentationController?.sourceRect = owner.shareButton.bounds
                owner.present(activityVC, animated: true)
            }
            .disposed(by: disposeBag)

        output.deleteCompleted
            .drive(with: self) { owner, _ in
                if owner.navigationController != nil && owner.presentingViewController == nil {
                    owner.navigationController?.popViewController(animated: true)
                } else {
                    owner.dismiss(animated: true)
                }
            }
            .disposed(by: disposeBag)

        output.isWidgetPinned
            .drive(with: self) { owner, isPinned in
                owner.updateWidgetToggleAppearance(isPinned: isPinned)
            }
            .disposed(by: disposeBag)
    }

    private func updateWidgetToggleAppearance(isPinned: Bool) {
        widgetToggleButton.layer.sublayers?
            .filter { $0 is CAGradientLayer }
            .forEach { $0.removeFromSuperlayer() }

        var config = UIButton.Configuration.plain()
        config.cornerStyle = .capsule
        config.buttonSize = .small
        config.imagePadding = 6
        config.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20)
        config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 13)

        if isPinned {
            config.image = UIImage(systemName: "checkmark")
            config.baseForegroundColor = .white
            config.title = NSLocalizedString("widget.added_to_widget", comment: "")
            config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
                var outgoing = incoming
                outgoing.font = FontSystem.galmuriMono(size: 12)
                return outgoing
            }
        } else {
            config.image = UIImage(systemName: "plus")
            config.baseForegroundColor = UIColor(red: 142/255, green: 142/255, blue: 147/255, alpha: 1)
            config.title = NSLocalizedString("widget.add_to_widget", comment: "")
            config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
                var outgoing = incoming
                outgoing.font = FontSystem.galmuriMono(size: 12)
                return outgoing
            }
        }

        widgetToggleButton.configuration = config
        widgetToggleButton.layoutIfNeeded()

        if isPinned {
            widgetToggleButton.backgroundColor = nil
            widgetToggleButton.layer.borderWidth = 0

            let gradient = CAGradientLayer()
            gradient.colors = [
                UIColor(red: 79/255, green: 123/255, blue: 254/255, alpha: 1).cgColor,
                UIColor(red: 2/255, green: 19/255, blue: 204/255, alpha: 1).cgColor
            ]
            gradient.startPoint = CGPoint(x: 0.5, y: 0)
            gradient.endPoint = CGPoint(x: 0.5, y: 1)
            gradient.frame = widgetToggleButton.bounds
            gradient.cornerRadius = widgetToggleButton.bounds.height / 2
            widgetToggleButton.layer.insertSublayer(gradient, at: 0)
        } else {
            widgetToggleButton.backgroundColor = UIColor(red: 242/255, green: 242/255, blue: 247/255, alpha: 1)
            widgetToggleButton.layer.borderWidth = 1
            widgetToggleButton.layer.borderColor = UIColor(red: 209/255, green: 209/255, blue: 214/255, alpha: 1).cgColor
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        saveButton.applyGradient(.highlight)
        shareButton.applyGradient(.highlight)

        let h = widgetToggleButton.bounds.height
        widgetToggleButton.layer.cornerRadius = h / 2
        for layer in widgetToggleButton.layer.sublayers ?? [] where layer is CAGradientLayer {
            layer.frame = widgetToggleButton.bounds
            layer.cornerRadius = h / 2
        }
    }
}
