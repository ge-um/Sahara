//
//  PhotoDetailViewController.swift
//  Sahara
//
//  Created by 금가경 on 9/26/25.
//

import MapKit
import SnapKit
import UIKit

final class PhotoDetailViewController: UIViewController {
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
        imageView.layer.masksToBounds = false
        return imageView
    }()

    private let cardContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 20
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 10
        view.layer.shadowOpacity = 0.08
        return view
    }()

    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        label.textColor = .label
        return label
    }()

    private let dateIconView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "calendar")
        imageView.tintColor = .systemBlue
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let memoTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "메모"
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .secondaryLabel
        return label
    }()

    private let memoLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.textColor = .label
        label.numberOfLines = 0
        return label
    }()

    private let locationTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "위치"
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .secondaryLabel
        return label
    }()

    private let mapView: MKMapView = {
        let mapView = MKMapView()
        mapView.layer.cornerRadius = 12
        mapView.clipsToBounds = true
        mapView.isUserInteractionEnabled = true
        return mapView
    }()

    private let locationLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.numberOfLines = 2
        return label
    }()

    private let closeButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = .systemGray5
        config.baseForegroundColor = .label
        config.image = UIImage(systemName: "xmark")
        config.cornerStyle = .capsule
        let button = UIButton(configuration: config)
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 4
        button.layer.shadowOpacity = 0.1
        return button
    }()

    private let buttonStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 12
        stackView.distribution = .fillEqually
        return stackView
    }()

    private let saveButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = .systemBlue
        config.baseForegroundColor = .white
        config.title = "저장"
        config.image = UIImage(systemName: "square.and.arrow.down")
        config.imagePlacement = .leading
        config.imagePadding = 8
        config.cornerStyle = .medium
        let button = UIButton(configuration: config)
        return button
    }()

    private let shareButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = .systemGreen
        config.baseForegroundColor = .white
        config.title = "공유"
        config.image = UIImage(systemName: "square.and.arrow.up")
        config.imagePlacement = .leading
        config.imagePadding = 8
        config.cornerStyle = .medium
        let button = UIButton(configuration: config)
        return button
    }()

    // MARK: - Properties
    private let photoMemo: PhotoMemo

    // MARK: - Init
    init(photoMemo: PhotoMemo) {
        self.photoMemo = photoMemo
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        configureData()
        setupActions()
    }

    // MARK: - Setup
    private func setupActions() {
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        saveButton.addTarget(self, action: #selector(saveButtonTapped), for: .touchUpInside)
        shareButton.addTarget(self, action: #selector(shareButtonTapped), for: .touchUpInside)
    }

    @objc private func closeButtonTapped() {
        dismiss(animated: true)
    }

    @objc private func saveButtonTapped() {
        guard let image = UIImage(data: photoMemo.imageData) else { return }
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
    }

    @objc private func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        let alert: UIAlertController
        if let error = error {
            alert = UIAlertController(title: "저장 실패", message: error.localizedDescription, preferredStyle: .alert)
        } else {
            alert = UIAlertController(title: "저장 완료", message: "사진이 앨범에 저장되었습니다.", preferredStyle: .alert)
        }
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }

    @objc private func shareButtonTapped() {
        guard let image = UIImage(data: photoMemo.imageData) else { return }
        let activityVC = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        activityVC.popoverPresentationController?.sourceView = shareButton
        present(activityVC, animated: true)
    }

    private func configureData() {
        // 이미지
        if let image = UIImage(data: photoMemo.imageData) {
            photoImageView.image = image
        }

        // 날짜
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy년 MM월 dd일 EEEE"
        dateFormatter.locale = Locale(identifier: "ko_KR")
        dateLabel.text = dateFormatter.string(from: photoMemo.date)

        // 메모
        if let memo = photoMemo.memo, !memo.isEmpty {
            memoLabel.text = memo
            memoTitleLabel.isHidden = false
            memoLabel.isHidden = false
        } else {
            memoTitleLabel.isHidden = true
            memoLabel.isHidden = true
        }

        // 위치
        if let latitude = photoMemo.latitude,
           let longitude = photoMemo.longitude {
            let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            let region = MKCoordinateRegion(
                center: coordinate,
                latitudinalMeters: 1000,
                longitudinalMeters: 1000
            )
            mapView.setRegion(region, animated: false)

            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            mapView.addAnnotation(annotation)

            // 역지오코딩으로 주소 가져오기
            let location = CLLocation(latitude: latitude, longitude: longitude)
            let geocoder = CLGeocoder()
            geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
                if let placemark = placemarks?.first {
                    let address = [
                        placemark.locality,
                        placemark.thoroughfare,
                        placemark.subThoroughfare
                    ].compactMap { $0 }.joined(separator: " ")
                    self?.locationLabel.text = address
                }
            }

            locationTitleLabel.isHidden = false
            mapView.isHidden = false
            locationLabel.isHidden = false
        } else {
            locationTitleLabel.isHidden = true
            mapView.isHidden = true
            locationLabel.isHidden = true
        }
    }

    // MARK: - Configure UI
    private func configureUI() {
        view.backgroundColor = .systemGroupedBackground

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(photoImageView)
        contentView.addSubview(buttonStackView)
        contentView.addSubview(cardContainerView)
        view.addSubview(closeButton)

        // 버튼 스택뷰에 버튼 추가
        buttonStackView.addArrangedSubview(saveButton)
        buttonStackView.addArrangedSubview(shareButton)

        // Card Container 내부
        cardContainerView.addSubview(dateIconView)
        cardContainerView.addSubview(dateLabel)
        cardContainerView.addSubview(memoTitleLabel)
        cardContainerView.addSubview(memoLabel)
        cardContainerView.addSubview(locationTitleLabel)
        cardContainerView.addSubview(mapView)
        cardContainerView.addSubview(locationLabel)

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

        buttonStackView.snp.makeConstraints { make in
            make.top.equalTo(photoImageView.snp.bottom).offset(16)
            make.horizontalEdges.equalToSuperview().inset(20)
            make.height.equalTo(50)
        }

        cardContainerView.snp.makeConstraints { make in
            make.top.equalTo(buttonStackView.snp.bottom).offset(16)
            make.horizontalEdges.equalToSuperview().inset(20)
            make.bottom.equalToSuperview().offset(-20)
        }

        dateIconView.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(20)
            make.width.height.equalTo(24)
        }

        dateLabel.snp.makeConstraints { make in
            make.leading.equalTo(dateIconView.snp.trailing).offset(12)
            make.trailing.equalToSuperview().inset(20)
            make.centerY.equalTo(dateIconView)
        }

        memoTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(dateIconView.snp.bottom).offset(24)
            make.horizontalEdges.equalToSuperview().inset(20)
        }

        memoLabel.snp.makeConstraints { make in
            make.top.equalTo(memoTitleLabel.snp.bottom).offset(8)
            make.horizontalEdges.equalToSuperview().inset(20)
        }

        locationTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(memoLabel.snp.bottom).offset(24)
            make.horizontalEdges.equalToSuperview().inset(20)
        }

        mapView.snp.makeConstraints { make in
            make.top.equalTo(locationTitleLabel.snp.bottom).offset(12)
            make.horizontalEdges.equalToSuperview().inset(20)
            make.height.equalTo(200)
        }

        locationLabel.snp.makeConstraints { make in
            make.top.equalTo(mapView.snp.bottom).offset(8)
            make.horizontalEdges.equalToSuperview().inset(20)
            make.bottom.equalToSuperview().inset(20)
        }

        closeButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(16)
            make.trailing.equalToSuperview().inset(20)
            make.width.height.equalTo(36)
        }
    }
}