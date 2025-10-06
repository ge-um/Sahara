//
//  CardInfoViewController.swift
//  Sahara
//
//  Created by 금가경 on 9/26/25.
//

import CoreLocation
import LocalAuthentication
import MapKit
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

    private let cancelButton: UIButton = {
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
    let coordinator: CardInfoCoordinator
    let viewModel: CardInfoViewModel
    let disposeBag = DisposeBag()
    var selectedLocation: CLLocation?
    var selectedImage: UIImage?
    let initialLocationSubject = PublishSubject<CLLocation>()
    let selectedDateRelay = BehaviorRelay<Date>(value: Date())

    init(viewModel: CardInfoViewModel) {
        self.viewModel = viewModel
        self.coordinator = CardInfoCoordinator(parentViewController: UIViewController())
        super.init(nibName: nil, bundle: nil)
        self.coordinator.parentViewController = self
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
        setupKeyboardDismiss()
        setupPlaceholder()
        setupKeyboardHandling()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        saveButton.applyGradient(.buttonPink)
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

    func updateMapView(with coordinate: CLLocationCoordinate2D) {
        contentView.mapView.isHidden = false
        contentView.mapViewHeightConstraint?.update(offset: 200)
        view.layoutIfNeeded()

        let region = MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: 1000,
            longitudinalMeters: 1000
        )
        contentView.mapView.setRegion(region, animated: true)

        contentView.mapView.removeAnnotations(contentView.mapView.annotations)
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        contentView.mapView.addAnnotation(annotation)
    }

    private func configureUI() {
        view.applyGradient(.cardInfoBackground)

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
        let locationSubject = PublishSubject<CLLocation>()
        let selectedImageSubject = BehaviorSubject<UIImage?>(value: nil)

        let photoImageTapGesture = UITapGestureRecognizer()
        contentView.photoImageView.addGestureRecognizer(photoImageTapGesture)

        photoImageTapGesture.rx.event
            .bind(with: self) { owner, _ in
                owner.coordinator.presentMediaSelection(selectedImageSubject: selectedImageSubject) { image, location, date in
                    owner.openPhotoEditor(with: image, location: location, date: date, selectedImageSubject: selectedImageSubject)
                }
            }
            .disposed(by: disposeBag)

        contentView.dateSelectButton.rx.tap
            .subscribe(with: self) { owner, _ in
                owner.coordinator.presentDatePicker(initialDate: owner.selectedDateRelay.value) { date in
                    owner.selectedDateRelay.accept(date)
                }
            }
            .disposed(by: disposeBag)

        selectedDateRelay
            .bind(with: self) { owner, date in
                let formatter = DateFormatter()
                formatter.locale = Locale.current
                formatter.dateStyle = .long
                owner.contentView.dateValueLabel.text = formatter.string(from: date)
            }
            .disposed(by: disposeBag)

        contentView.searchLocationButton.rx.tap
            .subscribe(with: self) { owner, _ in
                owner.coordinator.presentLocationSearch { coordinate, address in
                    let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
                    owner.selectedLocation = location
                    owner.contentView.selectedLocationLabel.text = address
                    owner.contentView.selectedLocationLabel.textColor = ColorSystem.labelSecondary
                    owner.updateMapView(with: coordinate)
                    locationSubject.onNext(location)
                }
            }
            .disposed(by: disposeBag)

        contentView.secretSwitch.rx.isOn
            .skip(1)
            .filter { $0 == true }
            .bind(with: self) { owner, _ in
                let biometricType = BiometricAuthManager.shared.biometricType

                if biometricType != .none {
                    BiometricAuthManager.shared.authenticate { success, error in
                        if !success {
                            owner.contentView.secretSwitch.isOn = false

                            if let error = error as NSError? {
                                if error.code == LAError.userCancel.rawValue || error.code == LAError.systemCancel.rawValue {
                                    return
                                }

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
                        }
                    }
                } else {
                    owner.contentView.secretSwitch.isOn = false
                    owner.showToast(message: NSLocalizedString("biometric.no_biometric", comment: ""))
                }
            }
            .disposed(by: disposeBag)

        let input = CardInfoViewModel.Input(
            selectedImage: selectedImageSubject.asObservable(),
            date: selectedDateRelay.asObservable(),
            memo: contentView.memoTextView.rx.text.asObservable(),
            location: Observable.merge(locationSubject.asObservable(), initialLocationSubject.asObservable()),
            isLocked: contentView.secretSwitch.rx.isOn.asObservable(),
            saveButtonTapped: saveButton.rx.tap.asObservable(),
            cancelButtonTapped: cancelButton.rx.tap.asObservable(),
            deleteButtonTapped: contentView.deleteButton.rx.tap.asObservable()
        )

        let output = viewModel.transform(input: input)

        output.editedImage
            .drive(with: self) { owner, image in
                owner.contentView.photoImageView.image = image
                if let image = image {
                    owner.contentView.updatePhotoImageHeight(for: image)
                }
            }
            .disposed(by: disposeBag)

        if output.isEditMode {
            contentView.deleteCard.isHidden = false
            contentView.secretSwitch.isOn = output.initialIsLocked
            selectedDateRelay.accept(output.initialDate)
            if let memo = output.initialMemo {
                contentView.memoTextView.text = memo
                contentView.memoTextView.textColor = ColorSystem.labelSecondary
            }
            if let location = output.initialLocation {
                initialLocationSubject.onNext(location)

                LocationUtility.reverseGeocode(location: location) { [weak self] address in
                    self?.contentView.selectedLocationLabel.text = address
                    self?.contentView.selectedLocationLabel.textColor = ColorSystem.labelSecondary
                }

                updateMapView(with: location.coordinate)
            }
        }

        output.hasImage
            .drive(with: self) { owner, hasImage in
                owner.contentView.photoImageView.isHidden = !hasImage
                owner.contentView.photoSelectButton.isHidden = hasImage
                if hasImage {
                    owner.selectedImage = owner.contentView.photoImageView.image
                    if let image = owner.contentView.photoImageView.image {
                        owner.contentView.updatePhotoImageHeight(for: image)
                    }
                } else {
                    owner.contentView.resetPhotoImageHeight()
                }
            }
            .disposed(by: disposeBag)

        contentView.photoSelectButton.rx.tap
            .bind(with: self) { owner, _ in
                owner.coordinator.presentMediaSelection(selectedImageSubject: selectedImageSubject) { image, location, date in
                    owner.openPhotoEditor(with: image, location: location, date: date, selectedImageSubject: selectedImageSubject)
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

        output.deleted
            .drive(with: self) { owner, _ in
                owner.coordinator.dismiss()
            }
            .disposed(by: disposeBag)
    }

    private func openPhotoEditor(with image: UIImage, location: CLLocation?, date: Date?, selectedImageSubject: BehaviorSubject<UIImage?>) {
        if let date = date {
            selectedDateRelay.accept(date)
        }

        if let location = location {
            selectedLocation = location
            initialLocationSubject.onNext(location)

            LocationUtility.reverseGeocode(location: location) { [weak self] address in
                self?.contentView.selectedLocationLabel.text = address.isEmpty ? "사진 위치" : address
                self?.contentView.selectedLocationLabel.textColor = ColorSystem.labelSecondary
                if let coord = self?.selectedLocation?.coordinate {
                    self?.updateMapView(with: coord)
                }
            }
        }

        coordinator.presentMediaEditor(image: image, selectedImageSubject: selectedImageSubject) { [weak self] editedImage in
            self?.selectedImage = editedImage
            self?.contentView.photoImageView.image = editedImage
            self?.contentView.photoImageView.isHidden = false
            self?.contentView.photoSelectButton.isHidden = true
            selectedImageSubject.onNext(editedImage)
        }
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

    private func setupKeyboardDismiss() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)

        contentView.memoTextView.delegate = self
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    private func setupPlaceholder() {
        contentView.memoTextView.attributedText = createPlaceholderText()
    }

    private func createPlaceholderText() -> NSAttributedString {
        return NSAttributedString(
            string: NSLocalizedString("card_info.memo_placeholder", comment: ""),
            attributes: [
                .foregroundColor: ColorSystem.labelPrimary,
                .font: FontSystem.galmuriMono(size: 16)
            ]
        )
    }
}

extension CardInfoViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == ColorSystem.labelPrimary {
            textView.text = ""
            textView.textColor = ColorSystem.labelSecondary
        }
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.attributedText = createPlaceholderText()
            contentView.characterCountLabel.text = "0"
            contentView.characterCountLabel.textColor = ColorSystem.labelPrimary
        }
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        return true
    }

    func textViewDidChange(_ textView: UITextView) {
        let count = textView.text.count
        contentView.characterCountLabel.text = "\(count)"
        contentView.characterCountLabel.textColor = ColorSystem.labelPrimary
    }
}
