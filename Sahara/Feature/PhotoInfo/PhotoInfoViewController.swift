//
//  PhotoInfoViewController.swift
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

final class PhotoInfoViewController: UIViewController {
    // MARK: - UI Components
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
        label.text = "날짜"
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
        label.text = "메모"
        label.font = .systemFont(ofSize: 14, weight: .semibold)
        label.textColor = .secondaryLabel
        return label
    }()

    private let memoTextView: UITextView = {
        let textView = UITextView()
        textView.text = "메모를 입력하세요 (300자 제한)"
        textView.textColor = .placeholderText
        textView.font = .systemFont(ofSize: 16)
        textView.backgroundColor = .clear
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 8, bottom: 12, right: 8)
        return textView
    }()

    private let locationCard: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemGroupedBackground
        view.layer.cornerRadius = 12
        return view
    }()

    private let locationLabel: UILabel = {
        let label = UILabel()
        label.text = "위치"
        label.font = .systemFont(ofSize: 14, weight: .semibold)
        label.textColor = .secondaryLabel
        return label
    }()

    private let selectedLocationLabel: UILabel = {
        let label = UILabel()
        label.text = "위치를 선택해주세요"
        label.font = .systemFont(ofSize: 14)
        label.textColor = .tertiaryLabel
        label.numberOfLines = 2
        return label
    }()

    private let searchLocationButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "위치 검색"
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
        config.title = "저장"
        button.configuration = config
        return button
    }()

    private let cancelButton: UIButton = {
        let button = UIButton()
        var config = UIButton.Configuration.plain()
        config.title = "취소"
        button.configuration = config
        return button
    }()

    // MARK: - Properties
    private let viewModel: PhotoInfoViewModel
    private let disposeBag = DisposeBag()
    private var selectedLocation: CLLocation?

    // MARK: - Init
    init(viewModel: PhotoInfoViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        configureNavigation()
        bind()
        setupKeyboardDismiss()
    }

    // MARK: - Setup
    private func setupKeyboardDismiss() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)

        memoTextView.delegate = self
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    // MARK: - Bind
    private func bind() {
        let locationSubject = PublishSubject<CLLocation>()

        searchLocationButton.rx.tap
            .subscribe(with: self) { owner, _ in
                owner.presentLocationSearch(locationSubject: locationSubject)
            }
            .disposed(by: disposeBag)

        let input = PhotoInfoViewModel.Input(
            date: datePicker.rx.date.asObservable(),
            memo: memoTextView.rx.text.asObservable(),
            location: locationSubject.asObservable(),
            saveButtonTapped: saveButton.rx.tap.asObservable(),
            cancelButtonTapped: cancelButton.rx.tap.asObservable()
        )

        let output = viewModel.transform(input: input)

        output.editedImage
            .drive(photoImageView.rx.image)
            .disposed(by: disposeBag)

        output.saved
            .drive(with: self) { owner, _ in
                owner.navigationController?.dismiss(animated: true)
            }
            .disposed(by: disposeBag)

        output.dismiss
            .drive(with: self) { owner, _ in
                owner.navigationController?.dismiss(animated: true)
            }
            .disposed(by: disposeBag)
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

    // MARK: - Configure UI
    private func configureUI() {
        view.backgroundColor = .systemGroupedBackground

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        contentView.addSubview(photoImageView)
        contentView.addSubview(dateCard)
        dateCard.addSubview(dateLabel)
        dateCard.addSubview(datePicker)

        contentView.addSubview(memoCard)
        memoCard.addSubview(memoLabel)
        memoCard.addSubview(memoTextView)

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
            make.height.equalTo(200)
            make.bottom.equalToSuperview().inset(16)
        }
    }

    private func configureNavigation() {
        navigationItem.title = "사진 정보"
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: cancelButton)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: saveButton)
    }
}

// MARK: - UITextViewDelegate
extension PhotoInfoViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == .placeholderText {
            textView.text = ""
            textView.textColor = .label
        }
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "메모를 입력하세요 (300자 제한)"
            textView.textColor = .placeholderText
        }
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let currentText = textView.text ?? ""
        guard let stringRange = Range(range, in: currentText) else { return false }
        let updatedText = currentText.replacingCharacters(in: stringRange, with: text)
        return updatedText.count <= 300
    }
}