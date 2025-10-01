//
//  PhotoDetailViewController.swift
//  Sahara
//
//  Created by 금가경 on 9/26/25.
//

import MapKit
import RealmSwift
import SnapKit
import UIKit

final class PhotoDetailViewController: UIViewController {
    private let photoMemoId: ObjectId
    private var photoMemo: PhotoMemo?
    private let realm = try! Realm()

    private var isFrontCardVisible = true

    private let cardContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()

    private let frontCardView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 20
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 4)
        view.layer.shadowRadius = 12
        view.layer.shadowOpacity = 0.1
        view.clipsToBounds = false
        return view
    }()

    private let backCardView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 20
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 4)
        view.layer.shadowRadius = 12
        view.layer.shadowOpacity = 0.1
        view.clipsToBounds = false
        view.isHidden = true
        return view
    }()

    private let photoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 20
        return imageView
    }()

    private let overlayView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        view.layer.cornerRadius = 20
        view.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        return view
    }()

    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        label.textColor = .white
        return label
    }()

    private let locationLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .white
        label.numberOfLines = 2
        return label
    }()

    private let swipeHintLabel: UILabel = {
        let label = UILabel()
        label.text = "← 스와이프하여 메모 보기"
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .white.withAlphaComponent(0.7)
        label.textAlignment = .center
        return label
    }()

    private let memoLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18)
        label.textColor = .label
        label.numberOfLines = 0
        label.textAlignment = .left
        return label
    }()

    private let backSwipeHintLabel: UILabel = {
        let label = UILabel()
        label.text = "→ 스와이프하여 사진 보기"
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
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
        button.layer.shadowOpacity = 0.2
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

    init(photoMemoId: ObjectId) {
        self.photoMemoId = photoMemoId
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        photoMemo = realm.object(ofType: PhotoMemo.self, forPrimaryKey: photoMemoId)
        configureUI()
        configureData()
        setupActions()
        setupGestures()
    }

    private func configureUI() {
        view.backgroundColor = .systemGroupedBackground

        view.addSubview(cardContainerView)
        view.addSubview(buttonStackView)
        view.addSubview(closeButton)

        cardContainerView.addSubview(frontCardView)
        cardContainerView.addSubview(backCardView)

        frontCardView.addSubview(photoImageView)
        frontCardView.addSubview(overlayView)
        overlayView.addSubview(dateLabel)
        overlayView.addSubview(locationLabel)
        overlayView.addSubview(swipeHintLabel)

        backCardView.addSubview(memoLabel)
        backCardView.addSubview(backSwipeHintLabel)

        buttonStackView.addArrangedSubview(saveButton)
        buttonStackView.addArrangedSubview(shareButton)

        cardContainerView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            make.horizontalEdges.equalToSuperview().inset(20)
            make.height.equalTo(500)
        }

        frontCardView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        backCardView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        photoImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        overlayView.snp.makeConstraints { make in
            make.horizontalEdges.bottom.equalToSuperview()
            make.height.equalTo(120)
        }

        dateLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.horizontalEdges.equalToSuperview().inset(20)
        }

        locationLabel.snp.makeConstraints { make in
            make.top.equalTo(dateLabel.snp.bottom).offset(8)
            make.horizontalEdges.equalToSuperview().inset(20)
        }

        swipeHintLabel.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-16)
            make.horizontalEdges.equalToSuperview().inset(20)
        }

        memoLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(40)
            make.horizontalEdges.equalToSuperview().inset(30)
            make.bottom.lessThanOrEqualTo(backSwipeHintLabel.snp.top).offset(-20)
        }

        backSwipeHintLabel.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-20)
            make.horizontalEdges.equalToSuperview().inset(20)
        }

        buttonStackView.snp.makeConstraints { make in
            make.top.equalTo(cardContainerView.snp.bottom).offset(20)
            make.horizontalEdges.equalToSuperview().inset(20)
            make.height.equalTo(50)
        }

        closeButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(16)
            make.trailing.equalToSuperview().inset(20)
            make.width.height.equalTo(36)
        }
    }

    private func configureData() {
        guard let photoMemo = photoMemo else { return }

        if let image = UIImage(data: photoMemo.imageData) {
            photoImageView.image = image
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy년 MM월 dd일 EEEE"
        dateFormatter.locale = Locale(identifier: "ko_KR")
        dateLabel.text = dateFormatter.string(from: photoMemo.date)

        if let memo = photoMemo.memo, !memo.isEmpty {
            memoLabel.text = memo
        } else {
            memoLabel.text = "메모가 없습니다."
        }

        if let latitude = photoMemo.latitude,
           let longitude = photoMemo.longitude {
            let location = CLLocation(latitude: latitude, longitude: longitude)
            let geocoder = CLGeocoder()
            geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
                if let placemark = placemarks?.first {
                    let address = [
                        placemark.locality,
                        placemark.thoroughfare,
                        placemark.subThoroughfare
                    ].compactMap { $0 }.joined(separator: " ")
                    DispatchQueue.main.async {
                        self?.locationLabel.text = address
                    }
                }
            }
        } else {
            locationLabel.text = ""
        }
    }

    private func setupActions() {
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        saveButton.addTarget(self, action: #selector(saveButtonTapped), for: .touchUpInside)
        shareButton.addTarget(self, action: #selector(shareButtonTapped), for: .touchUpInside)
    }

    private func setupGestures() {
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        swipeLeft.direction = .left
        cardContainerView.addGestureRecognizer(swipeLeft)

        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        swipeRight.direction = .right
        cardContainerView.addGestureRecognizer(swipeRight)
    }

    @objc private func handleSwipe(_ gesture: UISwipeGestureRecognizer) {
        if gesture.direction == .left && isFrontCardVisible {
            flipToBack()
        } else if gesture.direction == .right && !isFrontCardVisible {
            flipToFront()
        }
    }

    private func flipToBack() {
        UIView.transition(with: cardContainerView, duration: 0.6, options: [.transitionFlipFromLeft]) {
            self.frontCardView.isHidden = true
            self.backCardView.isHidden = false
        } completion: { _ in
            self.isFrontCardVisible = false
        }
    }

    private func flipToFront() {
        UIView.transition(with: cardContainerView, duration: 0.6, options: [.transitionFlipFromRight]) {
            self.frontCardView.isHidden = false
            self.backCardView.isHidden = true
        } completion: { _ in
            self.isFrontCardVisible = true
        }
    }

    @objc private func closeButtonTapped() {
        dismiss(animated: true)
    }

    @objc private func saveButtonTapped() {
        guard let photoMemo = photoMemo,
              let image = UIImage(data: photoMemo.imageData) else { return }
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
        guard let photoMemo = photoMemo,
              let image = UIImage(data: photoMemo.imageData) else { return }
        let activityVC = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        activityVC.popoverPresentationController?.sourceView = shareButton
        present(activityVC, animated: true)
    }
}
