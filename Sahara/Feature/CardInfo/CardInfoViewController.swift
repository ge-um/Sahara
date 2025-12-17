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
    let wasEditedRelay = BehaviorRelay<Bool>(value: false)
    let selectedFilterIndexRelay = BehaviorRelay<Int?>(value: nil)
    let cropMetadataRelay = BehaviorRelay<CropMetadata?>(value: nil)
    let rotationAngleRelay = BehaviorRelay<Double>(value: 0.0)

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
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        saveButton.applyGradient(.hotPink)
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
            make.leading.equalTo(customNavigationBar).offset(16)
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
        view.applyGradient(.mintToOrange)

        view.addSubview(customNavigationBar)
        view.addSubview(contentView)

        customNavigationBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.horizontalEdges.equalToSuperview()
            make.height.equalTo(54)
        }

        contentView.snp.makeConstraints { make in
            make.top.equalTo(customNavigationBar.snp.bottom)
            make.horizontalEdges.bottom.equalTo(view.safeAreaLayoutGuide)
        }

        contentView.scrollView.snp.remakeConstraints { make in
            make.top.equalTo(customNavigationBar.snp.bottom)
            make.horizontalEdges.bottom.equalTo(view.safeAreaLayoutGuide)
        }
    }

    private func bind() {
        let initialLocationRelay = BehaviorSubject<CLLocation?>(value: nil)
        let selectedLocationSubject = PublishSubject<(coordinate: CLLocationCoordinate2D, address: String)>()
        let selectedImageSubject = BehaviorSubject<UIImage?>(value: nil)

        let locationOutput = contentView.locationCard.bind(
            initialLocation: initialLocationRelay.asObservable(),
            selectedLocation: selectedLocationSubject.asObservable()
        )

        selectedLocationSubject
            .bind(with: self) { owner, result in
                let (coordinate, address) = result
                owner.contentView.locationCard.locationLabel.text = address
                owner.contentView.locationCard.locationLabel.textColor = ColorSystem.charcoal
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

        let photoImageTapGesture = UITapGestureRecognizer()
        contentView.photoImageView.addGestureRecognizer(photoImageTapGesture)

        let biometricOutput = contentView.biometricLockCard.bind(initialIsLocked: false)

        biometricOutput.presentPermissionAlert
            .drive(with: self) { owner, _ in
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
                owner.present(alert, animated: true)
            }
            .disposed(by: disposeBag)

        biometricOutput.showNoSupportToast
            .drive(with: self) { owner, message in
                owner.showToast(message: message)
            }
            .disposed(by: disposeBag)

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

        contentView.dateCard.selectButton.rx.tap
            .subscribe(with: self) { owner, _ in
                owner.coordinator.presentDatePicker(initialDate: owner.selectedDateRelay.value) { date in
                    owner.selectedDateRelay.accept(date)
                }
            }
            .disposed(by: disposeBag)

        contentView.dateCard.bind(date: selectedDateRelay.asDriver())

        contentView.deleteCard.deleteButton.rx.tap
            .bind(with: self) { owner, _ in
                owner.showDeleteAlert()
            }
            .disposed(by: disposeBag)

        contentView.photoEditButton.rx.tap
            .bind(with: self) { owner, _ in
                guard let _ = owner.contentView.photoImageView.image,
                      let currentImageSourceData = owner.imageSourceDataRelay.value else { return }

                owner.coordinator.presentMediaEditor(imageSource: currentImageSourceData, selectedImageSubject: selectedImageSubject) { [weak owner] editedImage, imageSourceData, wasEdited in
                    guard let owner = owner else { return }

                    Logger.cardInfo.info("Received editor metadata: filter=\(imageSourceData.appliedFilterIndex.orNil), crop=\(imageSourceData.cropMetadata.presenceLog), rotation=\(imageSourceData.rotationAngle)")

                    owner.contentView.photoImageView.image = editedImage
                    owner.contentView.photoImageView.isHidden = false
                    owner.contentView.photoSelectButton.isHidden = true
                    owner.contentView.updatePhotoImageHeight(for: editedImage)

                    owner.view.layoutIfNeeded()

                    owner.contentView.renderStickers(imageSourceData.stickers)

                    selectedImageSubject.onNext(editedImage)
                    owner.imageSourceDataRelay.accept(imageSourceData)
                    owner.wasEditedRelay.accept(wasEdited)
                    owner.selectedFilterIndexRelay.accept(imageSourceData.appliedFilterIndex)
                    owner.cropMetadataRelay.accept(imageSourceData.cropMetadata)
                    owner.rotationAngleRelay.accept(imageSourceData.rotationAngle)
                }
            }
            .disposed(by: disposeBag)

        let input = CardInfoViewModel.Input(
            selectedImage: selectedImageSubject.asObservable(),
            imageSourceData: imageSourceDataRelay.asObservable(),
            wasEdited: wasEditedRelay.asObservable(),
            selectedFilterIndex: selectedFilterIndexRelay.asObservable(),
            cropMetadata: cropMetadataRelay.asObservable(),
            rotationAngle: rotationAngleRelay.asObservable(),
            date: selectedDateRelay.asObservable(),
            memo: contentView.memoCard.textView.rx.text
                .withUnretained(self)
                .map { owner, text in
                    if owner.contentView.memoCard.textView.textColor == ColorSystem.darkGray {
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

        let output = viewModel.transform(input: input)

        photoImageTapGesture.rx.event
            .bind(with: self) { owner, _ in
                guard output.isEditMode else { return }
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

        output.editedImage
            .drive(with: self) { owner, image in
                owner.contentView.photoImageView.image = image
                if let image = image {
                    owner.contentView.updatePhotoImageHeight(for: image)
                }
            }
            .disposed(by: disposeBag)

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
        } else {
            contentView.memoCard.showPlaceholder()
        }

        output.hasImage
            .drive(with: self) { owner, hasImage in
                owner.contentView.photoImageView.isHidden = !hasImage
                owner.contentView.photoSelectButton.isHidden = hasImage
                owner.contentView.photoEditButton.isHidden = !hasImage || output.isEditMode
                if hasImage {
                    if let image = owner.contentView.photoImageView.image {
                        owner.contentView.updatePhotoImageHeight(for: image)
                    }
                } else {
                    owner.contentView.resetPhotoImageHeight()
                }
            }
            .disposed(by: disposeBag)

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

        output.dismiss
            .drive(with: self) { owner, _ in
                owner.coordinator.dismiss()
            }
            .disposed(by: disposeBag)

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

        let tapGesture = UITapGestureRecognizer()
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)

        tapGesture.rx.event
            .bind(with: self) { owner, _ in
                owner.view.endEditing(true)
            }
            .disposed(by: disposeBag)
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
