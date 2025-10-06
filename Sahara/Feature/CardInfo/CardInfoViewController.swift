//
//  CardInfoViewController.swift
//  Sahara
//
//  Created by 금가경 on 9/26/25.
//

import CoreLocation
import MapKit
import RxCocoa
import RxSwift
import SnapKit
import UIKit

final class CardInfoViewController: UIViewController {
    private let customNavigationBar = CustomNavigationBar()

    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        return scrollView
    }()

    private let contentView = UIView()

    private let photoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.layer.cornerRadius = 16
        imageView.clipsToBounds = true
        imageView.isUserInteractionEnabled = true
        return imageView
    }()

    private lazy var photoSelectButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "editBox"), for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.layer.cornerRadius = 16
        button.clipsToBounds = true
        return button
    }()

    private let dateCard: UIView = {
        let view = UIView()
        view.backgroundColor = ColorSystem.cardBackground
        view.layer.cornerRadius = 12
        return view
    }()

    private let dateLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("card_info.date", comment: "")
        label.font = FontSystem.galmuriMono(size: 14)
        label.textColor = ColorSystem.labelTitle
        return label
    }()

    private let dateIconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "calendar")
        imageView.tintColor = ColorSystem.labelPrimary
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let dateValueLabel: UILabel = {
        let label = UILabel()
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateStyle = .long
        label.text = formatter.string(from: Date())
        label.font = FontSystem.galmuriMono(size: 16)
        label.textColor = ColorSystem.labelPrimary
        return label
    }()

    private let dateSelectButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .clear
        return button
    }()

    private let memoCard: UIView = {
        let view = UIView()
        view.backgroundColor = ColorSystem.cardBackground
        view.layer.cornerRadius = 12
        return view
    }()

    private let memoLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("card_info.memo", comment: "")
        label.font = FontSystem.galmuriMono(size: 14)
        label.textColor = ColorSystem.labelTitle
        return label
    }()

    private let memoTextView: UITextView = {
        let textView = UITextView()
        textView.font = FontSystem.galmuriMono(size: 16)
        textView.textColor = ColorSystem.labelSecondary
        textView.backgroundColor = .clear
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 8, bottom: 12, right: 8)
        return textView
    }()

    private let characterCountLabel: UILabel = {
        let label = UILabel()
        label.text = "0"
        label.font = FontSystem.galmuriMono(size: 12)
        label.textColor = ColorSystem.labelPrimary
        label.textAlignment = .right
        return label
    }()

    private let locationCard: UIView = {
        let view = UIView()
        view.backgroundColor = ColorSystem.cardBackground
        view.layer.cornerRadius = 12
        return view
    }()

    private let locationLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("card_info.location", comment: "")
        label.font = FontSystem.galmuriMono(size: 14)
        label.textColor = ColorSystem.labelTitle
        return label
    }()

    private let selectedLocationLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("card_info.location_placeholder", comment: "")
        label.font = FontSystem.galmuriMono(size: 14)
        label.textColor = ColorSystem.labelPrimary
        label.numberOfLines = 2
        return label
    }()

    private let searchLocationButton: UIButton = {
        let button = UIButton()
        var config = UIButton.Configuration.filled()
        config.title = NSLocalizedString("card_info.search_location", comment: "")
        config.image = UIImage(systemName: "magnifyingglass")
        config.imagePlacement = .leading
        config.imagePadding = 8
        config.baseBackgroundColor = .clear
        config.baseForegroundColor = .black
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

    private let mapView: MKMapView = {
        let mapView = MKMapView()
        mapView.layer.cornerRadius = 12
        mapView.clipsToBounds = true
        mapView.isHidden = true
        return mapView
    }()

    private let deleteCard: UIView = {
        let view = UIView()
        view.backgroundColor = ColorSystem.cardBackground
        view.layer.cornerRadius = 12
        view.isHidden = true
        return view
    }()

    private let deleteLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("card_info.delete", comment: "")
        label.font = FontSystem.galmuriMono(size: 14)
        label.textColor = ColorSystem.labelTitle
        return label
    }()

    private lazy var deleteButton: UIButton = {
        let button = UIButton()
        var config = UIButton.Configuration.filled()
        config.title = NSLocalizedString("card_info.delete_button", comment: "")
        config.baseBackgroundColor = .systemRed
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

    private let saveButton: UIButton = {
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

    private let viewModel: CardInfoViewModel
    private let disposeBag = DisposeBag()
    private var selectedLocation: CLLocation?
    private var selectedImage: UIImage?
    private let initialLocationSubject = PublishSubject<CLLocation>()
    private var mapViewHeightConstraint: Constraint?
    private var photoImageHeightConstraint: Constraint?
    private let selectedDateRelay = BehaviorRelay<Date>(value: Date())

    init(viewModel: CardInfoViewModel) {
        self.viewModel = viewModel
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
        setupKeyboardDismiss()
        setupPlaceholder()
        setupKeyboardHandling()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        saveButton.applyGradient(.buttonPink)
        searchLocationButton.applyGradient(.searchLocationButton)
        photoSelectButton.applyGradient(.barBack)
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

    private func setupPlaceholder() {
        memoTextView.attributedText = createPlaceholderText()
    }

    private func setupKeyboardDismiss() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)

        memoTextView.delegate = self
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
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
                    owner.scrollView.contentInset = contentInsets
                    owner.scrollView.scrollIndicatorInsets = contentInsets
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
                    owner.scrollView.contentInset = .zero
                    owner.scrollView.scrollIndicatorInsets = .zero
                }
            }
            .disposed(by: disposeBag)
    }

    private func bind() {
        let locationSubject = PublishSubject<CLLocation>()
        let selectedImageSubject = BehaviorSubject<UIImage?>(value: nil)

        let photoImageTapGesture = UITapGestureRecognizer()
        photoImageView.addGestureRecognizer(photoImageTapGesture)

        photoImageTapGesture.rx.event
            .bind(with: self) { owner, _ in
                owner.presentMediaSelectionModal(selectedImageSubject: selectedImageSubject)
            }
            .disposed(by: disposeBag)

        dateSelectButton.rx.tap
            .subscribe(with: self) { owner, _ in
                owner.presentDatePicker()
            }
            .disposed(by: disposeBag)

        selectedDateRelay
            .bind(with: self) { owner, date in
                let formatter = DateFormatter()
                formatter.locale = Locale.current
                formatter.dateStyle = .long
                owner.dateValueLabel.text = formatter.string(from: date)
            }
            .disposed(by: disposeBag)

        searchLocationButton.rx.tap
            .subscribe(with: self) { owner, _ in
                owner.presentLocationSearch(locationSubject: locationSubject)
            }
            .disposed(by: disposeBag)

        let input = CardInfoViewModel.Input(
            selectedImage: selectedImageSubject.asObservable(),
            date: selectedDateRelay.asObservable(),
            memo: memoTextView.rx.text.asObservable(),
            location: Observable.merge(locationSubject.asObservable(), initialLocationSubject.asObservable()),
            saveButtonTapped: saveButton.rx.tap.asObservable(),
            cancelButtonTapped: cancelButton.rx.tap.asObservable(),
            deleteButtonTapped: deleteButton.rx.tap.asObservable()
        )

        let output = viewModel.transform(input: input)

        output.editedImage
            .drive(with: self) { owner, image in
                owner.photoImageView.image = image
                if let image = image {
                    owner.updatePhotoImageHeight(for: image)
                }
            }
            .disposed(by: disposeBag)

        if output.isEditMode {
            deleteCard.isHidden = false
            selectedDateRelay.accept(output.initialDate)
            if let memo = output.initialMemo {
                memoTextView.text = memo
                memoTextView.textColor = ColorSystem.labelSecondary
            }
            if let location = output.initialLocation {
                initialLocationSubject.onNext(location)

                LocationUtility.reverseGeocode(location: location) { [weak self] address in
                    self?.selectedLocationLabel.text = address
                    self?.selectedLocationLabel.textColor = ColorSystem.labelSecondary
                }

                updateMapView(with: location.coordinate)
            }
        }

        output.hasImage
            .drive(with: self) { owner, hasImage in
                owner.photoImageView.isHidden = !hasImage
                owner.photoSelectButton.isHidden = hasImage
                if hasImage {
                    owner.selectedImage = owner.photoImageView.image
                    if let image = owner.photoImageView.image {
                        owner.updatePhotoImageHeight(for: image)
                    }
                } else {
                    owner.resetPhotoImageHeight()
                }
            }
            .disposed(by: disposeBag)

        photoSelectButton.rx.tap
            .bind(with: self) { owner, _ in
                owner.presentMediaSelectionModal(selectedImageSubject: selectedImageSubject)
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
                    if let navController = owner.navigationController {
                        let viewControllers = navController.viewControllers
                        if output.isEditMode {
                            let targetIndex = viewControllers.count >= 4 ? viewControllers.count - 4 : 0
                            navController.popToViewController(viewControllers[targetIndex], animated: true)
                        } else {
                            navController.popToRootViewController(animated: true)
                        }
                    }
                } else {
                    if owner.navigationController != nil && owner.presentingViewController == nil {
                        owner.navigationController?.popViewController(animated: true)
                    } else {
                        owner.navigationController?.dismiss(animated: true)
                    }
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
                if owner.navigationController != nil && owner.presentingViewController == nil {
                    owner.navigationController?.popViewController(animated: true)
                } else {
                    owner.navigationController?.dismiss(animated: true)
                }
            }
            .disposed(by: disposeBag)

        output.deleted
            .drive(with: self) { owner, _ in
                if owner.navigationController != nil && owner.presentingViewController == nil {
                    owner.navigationController?.popViewController(animated: true)
                } else {
                    owner.navigationController?.dismiss(animated: true)
                }
            }
            .disposed(by: disposeBag)
    }

    private func presentMediaSelectionModal(selectedImageSubject: BehaviorSubject<UIImage?>) {
        let mediaSelectionVC = MediaSelectionViewController()
        mediaSelectionVC.onMediaSelected = { [weak self] image, location, date in
            self?.openPhotoEditor(with: image, location: location, date: date, selectedImageSubject: selectedImageSubject)
        }
        let navController = UINavigationController(rootViewController: mediaSelectionVC)
        if let sheet = navController.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
        }
        present(navController, animated: true)
    }

    private func openPhotoEditor(with image: UIImage, location: CLLocation?, date: Date?, selectedImageSubject: BehaviorSubject<UIImage?>) {
        dismiss(animated: true) { [weak self] in
            guard let self = self else { return }

            // 날짜 정보가 있으면 설정
            if let date = date {
                self.selectedDateRelay.accept(date)
            }

            // 위치 정보가 있으면 먼저 처리
            if let location = location {
                self.selectedLocation = location
                self.initialLocationSubject.onNext(location)

                LocationUtility.reverseGeocode(location: location) { [weak self] address in
                    self?.selectedLocationLabel.text = address.isEmpty ? "사진 위치" : address
                    self?.selectedLocationLabel.textColor = ColorSystem.labelSecondary
                    if let coord = self?.selectedLocation?.coordinate {
                        self?.updateMapView(with: coord)
                    }
                }
            }

            let viewModel = MediaEditorViewModel(originalImage: image)
            let editorVC = MediaEditorViewController(viewModel: viewModel)
            editorVC.onEditingComplete = { [weak self] editedImage in
                self?.selectedImage = editedImage
                self?.photoImageView.image = editedImage
                self?.photoImageView.isHidden = false
                self?.photoSelectButton.isHidden = true
                selectedImageSubject.onNext(editedImage)
            }
            let navController = UINavigationController(rootViewController: editorVC)
            navController.modalPresentationStyle = .fullScreen
            self.present(navController, animated: true)
        }
    }

    private func presentDatePicker() {
        let datePickerVC = DatePickerViewController(initialDate: selectedDateRelay.value)
        datePickerVC.onDateSelected = { [weak self] date in
            self?.selectedDateRelay.accept(date)
        }

        if let sheet = datePickerVC.sheetPresentationController {
            sheet.detents = [.medium()]
            sheet.prefersGrabberVisible = true
        }
        present(datePickerVC, animated: true)
    }

    private func presentLocationSearch(locationSubject: PublishSubject<CLLocation>) {
        let locationSearchVC = LocationSearchViewController()
        locationSearchVC.onLocationSelected = { [weak self] coordinate, address in
            let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            self?.selectedLocation = location
            self?.selectedLocationLabel.text = address
            self?.selectedLocationLabel.textColor = ColorSystem.labelSecondary
            self?.updateMapView(with: coordinate)
            locationSubject.onNext(location)
        }

        let nav = UINavigationController(rootViewController: locationSearchVC)
        present(nav, animated: true)
    }

    private func updateMapView(with coordinate: CLLocationCoordinate2D) {
        mapView.isHidden = false
        mapViewHeightConstraint?.update(offset: 200)
        view.layoutIfNeeded()

        let region = MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: 1000,
            longitudinalMeters: 1000
        )
        mapView.setRegion(region, animated: true)

        mapView.removeAnnotations(mapView.annotations)
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        mapView.addAnnotation(annotation)
    }

    private func configureUI() {
        view.applyGradient(.cardInfoBackground)

        view.addSubview(customNavigationBar)
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        customNavigationBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.horizontalEdges.equalToSuperview()
            make.height.equalTo(54)
        }

        contentView.addSubview(photoImageView)
        contentView.addSubview(photoSelectButton)
        contentView.addSubview(dateCard)
        dateCard.addSubview(dateLabel)
        dateCard.addSubview(dateValueLabel)
        dateCard.addSubview(dateIconImageView)
        dateCard.addSubview(dateSelectButton)

        contentView.addSubview(memoCard)
        memoCard.addSubview(memoLabel)
        memoCard.addSubview(memoTextView)
        memoCard.addSubview(characterCountLabel)

        contentView.addSubview(locationCard)
        locationCard.addSubview(locationLabel)
        locationCard.addSubview(selectedLocationLabel)
        locationCard.addSubview(searchLocationButton)
        locationCard.addSubview(mapView)

        contentView.addSubview(deleteCard)
        deleteCard.addSubview(deleteLabel)
        deleteCard.addSubview(deleteButton)

        scrollView.snp.makeConstraints { make in
            make.top.equalTo(customNavigationBar.snp.bottom)
            make.horizontalEdges.bottom.equalTo(view.safeAreaLayoutGuide)
        }

        contentView.snp.makeConstraints { make in
            make.edges.equalTo(scrollView)
            make.width.equalTo(scrollView)
        }

        photoImageView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.horizontalEdges.equalToSuperview().inset(20)
            photoImageHeightConstraint = make.height.equalTo(300).constraint
        }

        photoSelectButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.horizontalEdges.equalToSuperview().inset(20)
            make.height.equalTo(300)
        }

        dateCard.snp.makeConstraints { make in
            make.top.equalTo(photoImageView.snp.bottom).offset(20)
            make.horizontalEdges.equalToSuperview().inset(20)
            make.height.equalTo(80)
        }

        dateLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(16)
        }

        dateIconImageView.snp.makeConstraints { make in
            make.top.equalTo(dateLabel.snp.bottom).offset(8)
            make.leading.equalToSuperview().inset(16)
            make.width.height.equalTo(20)
            make.bottom.equalToSuperview().inset(16)
        }

        dateValueLabel.snp.makeConstraints { make in
            make.leading.equalTo(dateIconImageView.snp.trailing).offset(8)
            make.centerY.equalTo(dateIconImageView)
        }

        dateSelectButton.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        memoCard.snp.makeConstraints { make in
            make.top.equalTo(dateCard.snp.bottom).offset(16)
            make.horizontalEdges.equalToSuperview().inset(20)
        }

        memoLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(16)
        }

        memoTextView.snp.makeConstraints { make in
            make.top.equalTo(memoLabel.snp.bottom).offset(4)
            make.horizontalEdges.equalToSuperview().inset(8)
            make.height.equalTo(100)
        }

        characterCountLabel.snp.makeConstraints { make in
            make.top.equalTo(memoTextView.snp.bottom).offset(4)
            make.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().inset(12)
        }

        locationCard.snp.makeConstraints { make in
            make.top.equalTo(memoCard.snp.bottom).offset(16)
            make.horizontalEdges.equalToSuperview().inset(20)
        }

        locationLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(16)
        }

        selectedLocationLabel.snp.makeConstraints { make in
            make.top.equalTo(locationLabel.snp.bottom).offset(8)
            make.horizontalEdges.equalToSuperview().inset(16)
        }

        searchLocationButton.snp.makeConstraints { make in
            make.top.equalTo(selectedLocationLabel.snp.bottom).offset(12)
            make.horizontalEdges.equalToSuperview().inset(16)
            make.height.equalTo(44)
        }

        mapView.snp.makeConstraints { make in
            make.top.equalTo(searchLocationButton.snp.bottom).offset(12)
            make.horizontalEdges.equalToSuperview().inset(16)
            mapViewHeightConstraint = make.height.equalTo(0).constraint
            make.bottom.equalToSuperview().inset(16)
        }

        deleteCard.snp.makeConstraints { make in
            make.top.equalTo(locationCard.snp.bottom).offset(16)
            make.horizontalEdges.equalToSuperview().inset(20)
            make.bottom.equalToSuperview().offset(-100)
        }

        deleteLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(16)
        }

        deleteButton.snp.makeConstraints { make in
            make.top.equalTo(deleteLabel.snp.bottom).offset(12)
            make.horizontalEdges.equalToSuperview().inset(16)
            make.height.equalTo(44)
            make.bottom.equalToSuperview().inset(16)
        }
    }

    private func updatePhotoImageHeight(for image: UIImage) {
        let aspectRatio = image.size.height / image.size.width

        photoImageView.snp.remakeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.horizontalEdges.equalToSuperview().inset(20)
            make.height.equalTo(photoImageView.snp.width).multipliedBy(aspectRatio)
        }

        view.layoutIfNeeded()
    }

    private func resetPhotoImageHeight() {
        photoImageView.snp.remakeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.horizontalEdges.equalToSuperview().inset(20)
            make.height.equalTo(300)
        }

        view.layoutIfNeeded()
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
            characterCountLabel.text = "0"
            characterCountLabel.textColor = ColorSystem.labelPrimary
        }
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        return true
    }

    func textViewDidChange(_ textView: UITextView) {
        let count = textView.text.count
        characterCountLabel.text = "\(count)"
        characterCountLabel.textColor = ColorSystem.labelPrimary
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