import CoreLocation
import MapKit
import RxCocoa
import RxSwift
import SnapKit
import UIKit

final class CardInfoViewController: UIViewController {
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
        imageView.layer.shadowColor = UIColor.black.cgColor
        imageView.layer.shadowOffset = CGSize(width: 0, height: 2)
        imageView.layer.shadowRadius = 8
        imageView.layer.shadowOpacity = 0.1
        return imageView
    }()

    private lazy var photoSelectButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: "photo")
        config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 100, weight: .thin)
        config.baseForegroundColor = .systemGray3
        let button = UIButton(configuration: config)
        button.layer.cornerRadius = 16
        button.layer.borderWidth = 2
        button.layer.borderColor = UIColor.systemGray4.cgColor
        button.backgroundColor = .secondarySystemBackground
        return button
    }()

    private let dateCard: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemGroupedBackground
        view.layer.cornerRadius = 12
        return view
    }()

    private let datePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.date = Date()
        picker.datePickerMode = .date
        picker.calendar = .autoupdatingCurrent
        picker.preferredDatePickerStyle = .compact
        return picker
    }()

    private let dateLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("card_info.date", comment: "")
        label.font = .systemFont(ofSize: 14, weight: .semibold)
        label.textColor = .secondaryLabel
        return label
    }()

    private let memoCard: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemGroupedBackground
        view.layer.cornerRadius = 12
        return view
    }()

    private let memoLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("card_info.memo", comment: "")
        label.font = .systemFont(ofSize: 14, weight: .semibold)
        label.textColor = .secondaryLabel
        return label
    }()

    private let memoTextView: UITextView = {
        let textView = UITextView()
        textView.font = .systemFont(ofSize: 16)
        textView.backgroundColor = .clear
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 8, bottom: 12, right: 8)
        return textView
    }()

    private let characterCountLabel: UILabel = {
        let label = UILabel()
        label.text = "0/300"
        label.font = .systemFont(ofSize: 12)
        label.textColor = .label
        label.textAlignment = .right
        return label
    }()

    private let locationCard: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemGroupedBackground
        view.layer.cornerRadius = 12
        return view
    }()

    private let locationLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("card_info.location", comment: "")
        label.font = .systemFont(ofSize: 14, weight: .semibold)
        label.textColor = .secondaryLabel
        return label
    }()

    private let selectedLocationLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("card_info.location_placeholder", comment: "")
        label.font = .systemFont(ofSize: 14)
        label.textColor = .tertiaryLabel
        label.numberOfLines = 2
        return label
    }()

    private let searchLocationButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = NSLocalizedString("card_info.search_location", comment: "")
        config.baseBackgroundColor = .systemBlue
        config.baseForegroundColor = .white
        config.image = UIImage(systemName: "magnifyingglass")
        config.imagePlacement = .leading
        config.imagePadding = 8
        config.cornerStyle = .medium
        let button = UIButton(configuration: config)
        return button
    }()

    private let mapView: MKMapView = {
        let mapView = MKMapView()
        mapView.layer.cornerRadius = 12
        mapView.clipsToBounds = true
        mapView.isHidden = true
        return mapView
    }()

    private let saveButton: UIButton = {
        let button = UIButton()
        var config = UIButton.Configuration.plain()
        config.title = NSLocalizedString("common.save", comment: "")
        button.configuration = config
        return button
    }()

    private let cancelButton: UIButton = {
        let button = UIButton()
        var config = UIButton.Configuration.plain()
        config.title = NSLocalizedString("common.cancel", comment: "")
        button.configuration = config
        return button
    }()

    private let viewModel: CardInfoViewModel
    private let disposeBag = DisposeBag()
    private var selectedLocation: CLLocation?
    private var selectedImage: UIImage?
    private let initialLocationSubject = PublishSubject<CLLocation>()
    private var mapViewHeightConstraint: Constraint?

    init(viewModel: CardInfoViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        configureNavigation()
        bind()
        setupKeyboardDismiss()
        setupPlaceholder()
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

    private func bind() {
        let locationSubject = PublishSubject<CLLocation>()
        let selectedImageSubject = BehaviorSubject<UIImage?>(value: nil)

        searchLocationButton.rx.tap
            .subscribe(with: self) { owner, _ in
                owner.presentLocationSearch(locationSubject: locationSubject)
            }
            .disposed(by: disposeBag)

        let input = CardInfoViewModel.Input(
            selectedImage: selectedImageSubject.asObservable(),
            date: datePicker.rx.date.asObservable(),
            memo: memoTextView.rx.text.asObservable(),
            location: Observable.merge(locationSubject.asObservable(), initialLocationSubject.asObservable()),
            saveButtonTapped: saveButton.rx.tap.asObservable(),
            cancelButtonTapped: cancelButton.rx.tap.asObservable()
        )

        let output = viewModel.transform(input: input)

        output.editedImage
            .drive(photoImageView.rx.image)
            .disposed(by: disposeBag)

        output.hasImage
            .drive(with: self) { owner, hasImage in
                owner.photoImageView.isHidden = !hasImage
                owner.photoSelectButton.isHidden = hasImage
                if hasImage {
                    owner.selectedImage = owner.photoImageView.image
                }
            }
            .disposed(by: disposeBag)

        photoSelectButton.rx.tap
            .bind(with: self) { owner, _ in
                owner.presentMediaSelectionModal(selectedImageSubject: selectedImageSubject)
            }
            .disposed(by: disposeBag)

        output.saved
            .drive(with: self) { owner, success in
                if success {
                    owner.navigationController?.dismiss(animated: true)
                }
            }
            .disposed(by: disposeBag)

        output.saveError
            .drive(with: self) { owner, errorMessage in
                let alert = UIAlertController(
                    title: "저장 실패",
                    message: errorMessage,
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "확인", style: .default))
                owner.present(alert, animated: true)
            }
            .disposed(by: disposeBag)

        output.dismiss
            .drive(with: self) { owner, _ in
                owner.navigationController?.dismiss(animated: true)
            }
            .disposed(by: disposeBag)
    }

    private func presentMediaSelectionModal(selectedImageSubject: BehaviorSubject<UIImage?>) {
        let mediaSelectionVC = MediaSelectionViewController()
        mediaSelectionVC.onMediaSelected = { [weak self] image, location in
            self?.openPhotoEditor(with: image, location: location, selectedImageSubject: selectedImageSubject)
        }
        let navController = UINavigationController(rootViewController: mediaSelectionVC)
        if let sheet = navController.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
        }
        present(navController, animated: true)
    }

    private func openPhotoEditor(with image: UIImage, location: CLLocation?, selectedImageSubject: BehaviorSubject<UIImage?>) {
        dismiss(animated: true) { [weak self] in
            guard let self = self else { return }

            // 위치 정보가 있으면 먼저 처리
            if let location = location {
                self.selectedLocation = location
                self.initialLocationSubject.onNext(location)

                let geocoder = CLGeocoder()
                geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
                    guard let self = self,
                          let placemark = placemarks?.first else { return }

                    var addressString = ""
                    if let locality = placemark.locality {
                        addressString += locality
                    }
                    if let subLocality = placemark.subLocality {
                        addressString += " " + subLocality
                    }
                    if let thoroughfare = placemark.thoroughfare {
                        addressString += " " + thoroughfare
                    }

                    self.selectedLocationLabel.text = addressString.isEmpty ? "사진 위치" : addressString
                    self.selectedLocationLabel.textColor = .label
                    self.updateMapView(with: location.coordinate)
                }
            }

            let viewModel = PhotoEditorViewModel(originalImage: image)
            let editorVC = PhotoEditorViewController(viewModel: viewModel)
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

    private func presentLocationSearch(locationSubject: PublishSubject<CLLocation>) {
        let locationSearchVC = LocationSearchViewController()
        locationSearchVC.onLocationSelected = { [weak self] coordinate, address in
            let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            self?.selectedLocation = location
            self?.selectedLocationLabel.text = address
            self?.selectedLocationLabel.textColor = .label
            self?.updateMapView(with: coordinate)
            locationSubject.onNext(location)
        }

        let nav = UINavigationController(rootViewController: locationSearchVC)
        present(nav, animated: true)
    }

    private func updateMapView(with coordinate: CLLocationCoordinate2D) {
        mapView.isHidden = false
        mapViewHeightConstraint?.update(offset: 200)

        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }

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
        view.backgroundColor = .systemGroupedBackground

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        contentView.addSubview(photoImageView)
        contentView.addSubview(photoSelectButton)
        contentView.addSubview(dateCard)
        dateCard.addSubview(dateLabel)
        dateCard.addSubview(datePicker)

        contentView.addSubview(memoCard)
        memoCard.addSubview(memoLabel)
        memoCard.addSubview(memoTextView)
        memoCard.addSubview(characterCountLabel)

        contentView.addSubview(locationCard)
        locationCard.addSubview(locationLabel)
        locationCard.addSubview(selectedLocationLabel)
        locationCard.addSubview(searchLocationButton)
        locationCard.addSubview(mapView)

        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }

        contentView.snp.makeConstraints { make in
            make.edges.equalTo(scrollView)
            make.width.equalTo(scrollView)
        }

        photoImageView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.horizontalEdges.equalToSuperview().inset(20)
            make.height.equalTo(300)
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

        datePicker.snp.makeConstraints { make in
            make.top.equalTo(dateLabel.snp.bottom).offset(8)
            make.leading.equalToSuperview().inset(16)
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
            make.bottom.equalToSuperview().offset(-20)
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
    }

    private func configureNavigation() {
        navigationItem.title = NSLocalizedString("card_info.title", comment: "")
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: cancelButton)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: saveButton)
    }
}

extension CardInfoViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == .placeholderText {
            textView.text = ""
            textView.textColor = .label
        }
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.attributedText = createPlaceholderText()
            characterCountLabel.text = "0/300"
            characterCountLabel.textColor = .label
        }
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        return true
    }

    func textViewDidChange(_ textView: UITextView) {
        let count = textView.text.count
        characterCountLabel.text = "\(count)/300"

        // 250자 이상일 때 빨간색
        if count >= 250 {
            characterCountLabel.textColor = .systemRed
        } else {
            characterCountLabel.textColor = .label
        }
    }

    private func createPlaceholderText() -> NSAttributedString {
        return NSAttributedString(
            string: "메모를 남기고 카드 뒷면에서 확인해보세요!",
            attributes: [
                .foregroundColor: UIColor.placeholderText,
                .font: UIFont.systemFont(ofSize: 16)
            ]
        )
    }
}