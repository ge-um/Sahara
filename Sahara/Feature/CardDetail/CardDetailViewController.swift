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
    private let disposeBag = DisposeBag()
    private var isFrontCardVisible = true

    private let viewDidLoadRelay = PublishRelay<Void>()
    private let swipeLeftRelay = PublishRelay<Void>()
    private let swipeRightRelay = PublishRelay<Void>()
    private let deleteConfirmedRelay = PublishRelay<Void>()
    private var photoImageHeightConstraint: Constraint?

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

    private lazy var swipeHintLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("photo_detail.swipe_left_hint", comment: "")
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

    private lazy var backSwipeHintLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("photo_detail.swipe_right_hint", comment: "")
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

    private lazy var saveButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = ColorSystem.buttonYellow
        config.baseForegroundColor = .black
        config.cornerStyle = .capsule

        let font = FontSystem.galmuriMono(size: 12)
        let title = NSLocalizedString("common.save", comment: "")
        config.attributedTitle = AttributedString(title.attributedString(font: font, letterSpacing: -6, color: .black))

        let button = UIButton(configuration: config)
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 4
        button.layer.shadowOpacity = 0.2

        return button
    }()

    private lazy var shareButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = ColorSystem.buttonYellow
        config.baseForegroundColor = .black
        config.cornerStyle = .capsule

        let font = FontSystem.galmuriMono(size: 12)
        let title = NSLocalizedString("common.share", comment: "")
        config.attributedTitle = AttributedString(title.attributedString(font: font, letterSpacing: -6, color: .black))

        let button = UIButton(configuration: config)
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 4
        button.layer.shadowOpacity = 0.2

        return button
    }()

    private lazy var deleteButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = .systemRed
        config.baseForegroundColor = .white
        config.image = UIImage(systemName: "trash")
        config.cornerStyle = .capsule
        let button = UIButton(configuration: config)
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 4
        button.layer.shadowOpacity = 0.2
        return button
    }()

    init(photoMemoId: ObjectId) {
        self.viewModel = CardDetailViewModel(photoMemoId: photoMemoId)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        setupGestures()
        bind()
        viewDidLoadRelay.accept(())
    }

    private func configureUI() {
        view.applyGradientWithDots(.pinkBlue, dotSize: 5, spacing: 32, dotColor: .white)

        view.addSubview(cardContainerView)
        view.addSubview(buttonStackView)
        view.addSubview(deleteButton)
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
            make.horizontalEdges.equalToSuperview().inset(60)
            photoImageHeightConstraint = make.height.equalTo(300).constraint
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
            make.top.equalTo(cardContainerView.snp.bottom).offset(24)
            make.horizontalEdges.equalToSuperview().inset(20)
            make.height.equalTo(50)
        }

        deleteButton.snp.makeConstraints { make in
            make.top.equalTo(buttonStackView.snp.bottom).offset(12)
            make.centerX.equalToSuperview()
            make.width.equalTo(50)
            make.height.equalTo(50)
        }

        closeButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(16)
            make.trailing.equalToSuperview().inset(20)
            make.width.height.equalTo(36)
        }
    }

    private func setupGestures() {
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeLeft))
        swipeLeft.direction = .left
        cardContainerView.addGestureRecognizer(swipeLeft)

        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeRight))
        swipeRight.direction = .right
        cardContainerView.addGestureRecognizer(swipeRight)
    }

    @objc private func handleSwipeLeft() {
        guard isFrontCardVisible else { return }
        swipeLeftRelay.accept(())
    }

    @objc private func handleSwipeRight() {
        guard !isFrontCardVisible else { return }
        swipeRightRelay.accept(())
    }

    private func bind() {
        deleteButton.rx.tap
            .bind(with: self) { owner, _ in
                let alert = UIAlertController(
                    title: "사진 삭제",
                    message: "이 사진을 삭제하시겠습니까?",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "취소", style: .cancel))
                alert.addAction(UIAlertAction(title: "삭제", style: .destructive) { _ in
                    owner.deleteConfirmedRelay.accept(())
                })
                owner.present(alert, animated: true)
            }
            .disposed(by: disposeBag)

        let input = CardDetailViewModel.Input(
            viewDidLoad: viewDidLoadRelay.asObservable(),
            closeButtonTapped: closeButton.rx.tap.asObservable(),
            saveButtonTapped: saveButton.rx.tap.asObservable(),
            shareButtonTapped: shareButton.rx.tap.asObservable(),
            deleteConfirmed: deleteConfirmedRelay.asObservable(),
            swipeLeft: swipeLeftRelay.asObservable(),
            swipeRight: swipeRightRelay.asObservable()
        )

        let output = viewModel.transform(input: input)

        output.photoImage
            .drive(with: self) { owner, image in
                owner.photoImageView.image = image
                if let image = image {
                    owner.updatePhotoImageHeight(for: image)
                }
            }
            .disposed(by: disposeBag)

        output.dateText
            .drive(dateLabel.rx.text)
            .disposed(by: disposeBag)

        output.locationText
            .drive(locationLabel.rx.text)
            .disposed(by: disposeBag)

        output.memoText
            .drive(memoLabel.rx.text)
            .disposed(by: disposeBag)

        output.shouldFlipToBack
            .drive(with: self) { owner, _ in
                owner.flipToBack()
            }
            .disposed(by: disposeBag)

        output.shouldFlipToFront
            .drive(with: self) { owner, _ in
                owner.flipToFront()
            }
            .disposed(by: disposeBag)

        output.shouldDismiss
            .drive(with: self) { owner, _ in
                owner.dismiss(animated: true)
            }
            .disposed(by: disposeBag)

        output.saveResult
            .drive(with: self) { owner, result in
                let alert: UIAlertController
                switch result {
                case .success:
                    alert = UIAlertController(title: NSLocalizedString("photo_detail.save_success", comment: ""), message: NSLocalizedString("photo_detail.save_success_message", comment: ""), preferredStyle: .alert)
                case .failure(let error):
                    alert = UIAlertController(title: NSLocalizedString("photo_detail.save_failed", comment: ""), message: error.localizedDescription, preferredStyle: .alert)
                }
                alert.addAction(UIAlertAction(title: NSLocalizedString("common.ok", comment: ""), style: .default))
                owner.present(alert, animated: true)
            }
            .disposed(by: disposeBag)

        output.shareImage
            .drive(with: self) { owner, image in
                let activityVC = UIActivityViewController(activityItems: [image], applicationActivities: nil)
                activityVC.popoverPresentationController?.sourceView = owner.shareButton
                owner.present(activityVC, animated: true)
            }
            .disposed(by: disposeBag)

        output.deleteCompleted
            .drive(with: self) { owner, _ in
                owner.dismiss(animated: true) {
                    NotificationCenter.default.post(name: AppNotification.photoDeleted.name, object: nil)
                }
            }
            .disposed(by: disposeBag)
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

    private func updatePhotoImageHeight(for image: UIImage) {
        let imageWidth = view.frame.width - 120
        let imageHeight = image.heightForWidth(imageWidth)

        photoImageHeightConstraint?.update(offset: imageHeight)

        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
}
