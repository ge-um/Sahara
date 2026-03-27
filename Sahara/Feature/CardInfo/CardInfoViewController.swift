//
//  CardInfoViewController.swift
//  Sahara
//
//  Created by 금가경 on 9/26/25.
//

import CoreLocation
import LocalAuthentication
import MapKit
import OSLog
import RxCocoa
import RxSwift
import SnapKit
import UIKit
import UniformTypeIdentifiers

final class CardInfoViewController: UIViewController {
    private let customNavigationBar = CustomNavigationBar()

    let saveButton: UIButton = {
        let button = UIButton()
        var config = UIButton.Configuration.filled()
        config.title = NSLocalizedString("common.save", comment: "")
        config.baseBackgroundColor = .clear
        config.baseForegroundColor = .white
        config.cornerStyle = .medium
        config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)

        var titleAttr = AttributeContainer()
        titleAttr.font = FontSystem.galmuriMono(size: 14)
        config.attributedTitle = AttributedString(config.title ?? "", attributes: titleAttr)

        button.configuration = config
        button.layer.cornerRadius = 8
        button.clipsToBounds = true
        return button
    }()

    let cancelButton: UIButton = {
        let button = UIButton()
        var config = UIButton.Configuration.filled()
        config.image = UIImage(named: "xmark")
        config.baseBackgroundColor = .white
        config.baseForegroundColor = .black
        config.cornerStyle = .medium
        button.configuration = config
        return button
    }()

    let contentView = CardInfoView()
    let coordinator: CardInfoCoordinatorProtocol
    let viewModel: CardInfoViewModel
    let disposeBag = DisposeBag()
    let selectedDateRelay = BehaviorRelay<Date>(value: Date())
    let deleteConfirmedRelay = PublishRelay<Void>()
    let imageSourceDataRelay = BehaviorRelay<ImageSourceData?>(value: nil)
    private let selectedImageSubject = BehaviorSubject<UIImage?>(value: nil)
    private let initialLocationRelay = BehaviorSubject<CLLocation?>(value: nil)

    init(viewModel: CardInfoViewModel, coordinator: CardInfoCoordinatorProtocol) {
        self.viewModel = viewModel
        self.coordinator = coordinator
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        configureUI()
        setupCustomNavigationBar()
        bind()
        setupKeyboardHandling()
        #if targetEnvironment(macCatalyst)
        setupDropInteraction()
        #endif
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        saveButton.applyGradient(.ctaPink)
        contentView.applyGradients()
    }

    private func setupCustomNavigationBar() {
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: FontSystem.galmuriMono(size: 14),
            .kern: -0.84
        ]
        let attributedTitle = NSAttributedString(
            string: NSLocalizedString("card_info.title", comment: ""),
            attributes: titleAttributes
        )
        customNavigationBar.configure(title: attributedTitle.string)

        view.addSubview(cancelButton)
        view.addSubview(saveButton)

        cancelButton.snp.makeConstraints { make in
            make.leading.equalTo(customNavigationBar.contentLeadingGuide.snp.trailing)
            make.centerY.equalTo(customNavigationBar)
            make.width.equalTo(48)
            make.height.equalTo(44)
        }

        saveButton.snp.makeConstraints { make in
            make.trailing.equalTo(customNavigationBar).inset(16)
            make.centerY.equalTo(customNavigationBar)
            make.width.greaterThanOrEqualTo(48)
            make.height.equalTo(44)
        }

        customNavigationBar.hideLeftButton()
    }

    private func configureUI() {
        view.applyBackgroundConfig(BackgroundThemeService.shared.currentConfig.value)

        view.addSubview(customNavigationBar)
        view.addSubview(contentView)

        customNavigationBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.horizontalEdges.equalToSuperview()
            make.height.equalTo(54)
        }

        contentView.snp.makeConstraints { make in
            make.top.equalTo(customNavigationBar.snp.bottom)
            make.bottom.equalTo(view.safeAreaLayoutGuide)
            if UIDevice.current.userInterfaceIdiom == .phone {
                make.horizontalEdges.equalTo(view.safeAreaLayoutGuide)
            } else {
                make.centerX.equalToSuperview()
                make.width.lessThanOrEqualTo(600)
                make.horizontalEdges.equalTo(view.safeAreaLayoutGuide).priority(.medium)
            }
        }

        contentView.scrollView.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func bind() {
        let selectedLocationSubject = PublishSubject<(coordinate: CLLocationCoordinate2D, address: String)>()

        let locationOutput = bindLocationCard(
            initialLocationRelay: initialLocationRelay,
            selectedLocationSubject: selectedLocationSubject
        )
        let biometricOutput = bindBiometricLockCard()

        bindDateCard()
        bindDeleteCard()
        bindPhotoActions(
            selectedImageSubject: selectedImageSubject,
            initialLocationRelay: initialLocationRelay
        )

        let input = createViewModelInput(
            selectedImageSubject: selectedImageSubject,
            locationOutput: locationOutput,
            biometricOutput: biometricOutput
        )
        let output = viewModel.transform(input: input)

        setupInitialData(output, initialLocationRelay: initialLocationRelay)
        bindImageOutputs(output)
        bindSaveOutputs(output)
        bindDeleteOutputs(output)
        bindDismissOutput(output)

        bindPhotoImageTapGesture(
            selectedImageSubject: selectedImageSubject,
            initialLocationRelay: initialLocationRelay,
            isEditMode: output.isEditMode
        )
        bindKeyboardDismissGesture()
    }

    private func setupKeyboardHandling() {
        NotificationCenter.default.rx.notification(UIResponder.keyboardWillShowNotification)
            .withUnretained(self)
            .bind { owner, notification in
                guard let userInfo = notification.userInfo,
                      let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
                      let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval else {
                    return
                }

                let keyboardHeight = keyboardFrame.height
                let contentInsets = UIEdgeInsets(top: 0, left: 0, bottom: keyboardHeight, right: 0)

                UIView.animate(withDuration: duration) {
                    owner.contentView.scrollView.contentInset = contentInsets
                    owner.contentView.scrollView.scrollIndicatorInsets = contentInsets
                }
            }
            .disposed(by: disposeBag)

        NotificationCenter.default.rx.notification(UIResponder.keyboardWillHideNotification)
            .withUnretained(self)
            .bind { owner, notification in
                guard let userInfo = notification.userInfo,
                      let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval else {
                    return
                }

                UIView.animate(withDuration: duration) {
                    owner.contentView.scrollView.contentInset = .zero
                    owner.contentView.scrollView.scrollIndicatorInsets = .zero
                }
            }
            .disposed(by: disposeBag)
    }

    private func showDeleteAlert() {
        AlertUtility.showDeleteConfirmation(on: self) { [weak self] in
            self?.deleteConfirmedRelay.accept(())
        }
    }
}

extension CardInfoViewController {

    private func bindLocationCard(
        initialLocationRelay: BehaviorSubject<CLLocation?>,
        selectedLocationSubject: PublishSubject<(coordinate: CLLocationCoordinate2D, address: String)>
    ) -> LocationSelectionCardViewModel.Output {
        let locationOutput = contentView.locationCard.bind(
            initialLocation: initialLocationRelay.asObservable(),
            selectedLocation: selectedLocationSubject.asObservable()
        )

        selectedLocationSubject
            .bind(with: self) { owner, result in
                let (coordinate, address) = result
                owner.contentView.locationCard.locationLabel.text = address
                owner.contentView.locationCard.locationLabel.textColor = .token(.textPrimary)
                owner.contentView.locationCard.removeButton.isHidden = false
                owner.contentView.locationCard.updateMapView(with: coordinate)
            }
            .disposed(by: disposeBag)

        locationOutput.presentLocationSearch
            .drive(with: self) { owner, _ in
                owner.coordinator.presentLocationSearch { coordinate, address in
                    selectedLocationSubject.onNext((coordinate, address))
                }
            }
            .disposed(by: disposeBag)

        return locationOutput
    }

    private func bindBiometricLockCard() -> BiometricLockCardViewModel.Output {
        let biometricOutput = contentView.biometricLockCard.bind(initialIsLocked: false)

        biometricOutput.presentPermissionAlert
            .drive(with: self) { owner, _ in
                owner.presentBiometricPermissionAlert()
            }
            .disposed(by: disposeBag)

        biometricOutput.showNoSupportToast
            .drive(with: self) { owner, message in
                owner.showToast(message: message)
            }
            .disposed(by: disposeBag)

        return biometricOutput
    }

    private func bindDateCard() {
        contentView.dateCard.selectButton.rx.tap
            .subscribe(with: self) { owner, _ in
                owner.coordinator.presentDatePicker(initialDate: owner.selectedDateRelay.value) { date in
                    owner.selectedDateRelay.accept(date)
                }
            }
            .disposed(by: disposeBag)

        contentView.dateCard.bind(date: selectedDateRelay.asDriver())
    }

    private func bindDeleteCard() {
        contentView.deleteCard.deleteButton.rx.tap
            .bind(with: self) { owner, _ in
                owner.showDeleteAlert()
            }
            .disposed(by: disposeBag)
    }

    private func bindPhotoActions(
        selectedImageSubject: BehaviorSubject<UIImage?>,
        initialLocationRelay: BehaviorSubject<CLLocation?>
    ) {
        contentView.photoSelectButton.rx.tap
            .bind(with: self) { owner, _ in
                owner.coordinator.presentMediaSelection(selectedImageSubject: selectedImageSubject) { imageSource, location, date in
                    selectedImageSubject.onNext(imageSource.image)
                    owner.imageSourceDataRelay.accept(imageSource)

                    if let date = date {
                        owner.selectedDateRelay.accept(date)
                    }

                    if let location = location {
                        initialLocationRelay.onNext(location)
                    }
                }
            }
            .disposed(by: disposeBag)

        contentView.photoEditButton.rx.tap
            .bind(with: self) { owner, _ in
                guard let currentImage = owner.contentView.photoImageView.image else { return }

                let currentImageSourceData = owner.imageSourceDataRelay.value ?? ImageSourceData(image: currentImage)

                owner.coordinator.presentMediaEditor(imageSource: currentImageSourceData, selectedImageSubject: selectedImageSubject) { [weak owner] displayImage, imageSourceData in
                    guard let owner = owner else { return }

                    Logger.cardInfo.info("Received editor result: stickers=\(imageSourceData.stickers.count), filter=\(imageSourceData.filterIndex ?? 0)")

                    owner.contentView.photoImageView.image = displayImage
                    owner.contentView.photoImageView.isHidden = false
                    owner.contentView.photoSelectButton.isHidden = true
                    owner.contentView.updatePhotoImageHeight(for: displayImage)

                    selectedImageSubject.onNext(displayImage)
                    owner.imageSourceDataRelay.accept(imageSourceData)
                }
            }
            .disposed(by: disposeBag)
    }

    private func createViewModelInput(
        selectedImageSubject: BehaviorSubject<UIImage?>,
        locationOutput: LocationSelectionCardViewModel.Output,
        biometricOutput: BiometricLockCardViewModel.Output
    ) -> CardInfoViewModel.Input {
        return CardInfoViewModel.Input(
            selectedImage: selectedImageSubject.asObservable(),
            imageSourceData: imageSourceDataRelay.asObservable(),
            date: selectedDateRelay.asObservable(),
            memo: contentView.memoCard.textView.rx.text
                .withUnretained(self)
                .map { owner, text in
                    if owner.contentView.memoCard.textView.textColor == .token(.textSecondary) {
                        return nil
                    }
                    return text
                }
                .asObservable(),
            customFolder: contentView.folderCard.selectedFolderRelay.asObservable(),
            location: locationOutput.location.asObservable(),
            isLocked: biometricOutput.isLocked.asObservable(),
            saveButtonTapped: saveButton.rx.tap.asObservable(),
            cancelButtonTapped: cancelButton.rx.tap.asObservable(),
            deleteButtonTapped: deleteConfirmedRelay.asObservable()
        )
    }

    private func setupInitialData(
        _ output: CardInfoViewModel.Output,
        initialLocationRelay: BehaviorSubject<CLLocation?>
    ) {
        selectedDateRelay.accept(output.initialDate)
        contentView.biometricLockCard.lockSwitch.isOn = output.initialIsLocked

        if output.isEditMode {
            contentView.deleteCard.isHidden = false
            if let memo = output.initialMemo {
                contentView.memoCard.setMemo(memo)
            } else {
                contentView.memoCard.showPlaceholder()
            }
            if let location = output.initialLocation {
                initialLocationRelay.onNext(location)
            }
            contentView.folderCard.setFolder(output.initialCustomFolder)

            if let imageSourceData = output.initialImageSourceData {
                imageSourceDataRelay.accept(imageSourceData)
            }
        } else {
            contentView.memoCard.showPlaceholder()
        }
    }

    private func bindImageOutputs(_ output: CardInfoViewModel.Output) {
        output.editedImage
            .drive(with: self) { owner, image in
                owner.contentView.photoImageView.image = image
                if let image = image {
                    owner.contentView.updatePhotoImageHeight(for: image)
                }
            }
            .disposed(by: disposeBag)

        output.hasImage
            .drive(with: self) { owner, hasImage in
                owner.contentView.photoImageView.isHidden = !hasImage
                owner.contentView.photoSelectButton.isHidden = hasImage
                owner.contentView.photoEditButton.isHidden = !hasImage
                if hasImage {
                    if let image = owner.contentView.photoImageView.image {
                        owner.contentView.updatePhotoImageHeight(for: image)
                    }
                } else {
                    owner.contentView.resetPhotoImageHeight()
                }
            }
            .disposed(by: disposeBag)
    }

    private func bindSaveOutputs(_ output: CardInfoViewModel.Output) {
        Observable.zip(
            output.saved.asObservable(),
            output.shouldPopToList.asObservable()
        )
        .observe(on: MainScheduler.instance)
        .bind(with: self) { owner, result in
            let (success, shouldPopToList) = result
            if success {
                owner.contentView.folderCard.refreshFolderTags()
                if shouldPopToList {
                    owner.coordinator.popToList(isEditMode: output.isEditMode)
                } else {
                    owner.coordinator.dismiss()
                }
            }
        }
        .disposed(by: disposeBag)

        output.saveError
            .drive(with: self) { owner, errorMessage in
                owner.showToast(message: errorMessage)
            }
            .disposed(by: disposeBag)
    }

    private func bindDeleteOutputs(_ output: CardInfoViewModel.Output) {
        Observable.zip(
            output.deleted.asObservable(),
            output.shouldPopToListOnDelete.asObservable()
        )
        .observe(on: MainScheduler.instance)
        .bind(with: self) { owner, result in
            let (_, shouldPopToList) = result
            if shouldPopToList {
                owner.coordinator.popToList(isEditMode: output.isEditMode)
            } else {
                owner.coordinator.dismiss()
            }
        }
        .disposed(by: disposeBag)
    }

    private func bindDismissOutput(_ output: CardInfoViewModel.Output) {
        output.dismiss
            .drive(with: self) { owner, _ in
                owner.coordinator.dismiss()
            }
            .disposed(by: disposeBag)
    }

    private func bindPhotoImageTapGesture(
        selectedImageSubject: BehaviorSubject<UIImage?>,
        initialLocationRelay: BehaviorSubject<CLLocation?>,
        isEditMode: Bool
    ) {
        let photoImageTapGesture = UITapGestureRecognizer()
        contentView.photoImageView.addGestureRecognizer(photoImageTapGesture)

        photoImageTapGesture.rx.event
            .bind(with: self) { owner, _ in
                guard isEditMode else { return }
                owner.coordinator.presentMediaSelection(selectedImageSubject: selectedImageSubject) { imageSource, location, date in
                    selectedImageSubject.onNext(imageSource.image)
                    owner.imageSourceDataRelay.accept(imageSource)

                    if let date = date {
                        owner.selectedDateRelay.accept(date)
                    }

                    if let location = location {
                        initialLocationRelay.onNext(location)
                    }
                }
            }
            .disposed(by: disposeBag)
    }

    private func bindKeyboardDismissGesture() {
        let tapGesture = UITapGestureRecognizer()
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)

        tapGesture.rx.event
            .bind(with: self) { owner, _ in
                owner.view.endEditing(true)
            }
            .disposed(by: disposeBag)
    }

    #if targetEnvironment(macCatalyst)
    private func setupDropInteraction() {
        contentView.addPhotoContainerInteraction(UIDropInteraction(delegate: self))
        contentView.photoSelectButton.addInteraction(UIDropInteraction(delegate: self))
    }
    #endif

    private func presentBiometricPermissionAlert() {
        let alert = UIAlertController(
            title: NSLocalizedString("biometric.permission_required", comment: ""),
            message: NSLocalizedString("biometric.permission_message", comment: ""),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: NSLocalizedString("media_selection.go_to_settings", comment: ""), style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        })
        alert.addAction(UIAlertAction(title: NSLocalizedString("common.cancel", comment: ""), style: .cancel))
        present(alert, animated: true)
    }
}

#if targetEnvironment(macCatalyst)
extension CardInfoViewController: UIDropInteractionDelegate {
    func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
        session.canLoadObjects(ofClass: UIImage.self)
    }

    func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
        UIDropProposal(operation: .copy)
    }

    func dropInteraction(_ interaction: UIDropInteraction, sessionDidEnter session: UIDropSession) {
        contentView.setDropHighlight(true)
    }

    func dropInteraction(_ interaction: UIDropInteraction, sessionDidExit session: UIDropSession) {
        contentView.setDropHighlight(false)
    }

    func dropInteraction(_ interaction: UIDropInteraction, concludeDrop session: UIDropSession) {
        contentView.setDropHighlight(false)
    }

    func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
        guard let item = session.items.first else { return }
        let provider = item.itemProvider

        let imageType = provider.registeredTypeIdentifiers
            .compactMap { UTType($0) }
            .first { $0.conforms(to: .image) }
            ?? .image

        _ = provider.loadDataRepresentation(for: imageType) { [weak self] data, error in
            if let data, let result = ImageFormatConverter.createImageSourceData(from: data) {
                DispatchQueue.main.async {
                    self?.applyDroppedImage(result: result)
                }
            } else {
                DispatchQueue.main.async {
                    self?.loadDroppedImageFallback(from: session)
                }
            }
        }
    }

    private func loadDroppedImageFallback(from session: UIDropSession) {
        _ = session.loadObjects(ofClass: UIImage.self) { [weak self] images in
            guard let image = images.first as? UIImage else { return }
            DispatchQueue.main.async {
                let imageSource = ImageSourceData(image: image)
                self?.selectedImageSubject.onNext(image)
                self?.imageSourceDataRelay.accept(imageSource)
            }
        }
    }
}
#endif

extension CardInfoViewController {
    func applyDroppedImage(result: ImageFormatConverter.ImageSourceResult) {
        selectedImageSubject.onNext(result.imageSource.image)
        imageSourceDataRelay.accept(result.imageSource)

        if let date = result.metadata.date {
            selectedDateRelay.accept(date)
        }
        if let location = result.metadata.location {
            initialLocationRelay.onNext(location)
        }
    }
}
