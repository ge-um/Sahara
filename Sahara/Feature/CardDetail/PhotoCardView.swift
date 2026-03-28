//
//  PhotoCardView.swift
//  Sahara
//
//  Created by 금가경 on 1/11/25.
//

import Kingfisher
import OSLog
import RxCocoa
import RxSwift
import SnapKit
import UIKit

final class PhotoCardView: UIView {
    private var isFrontCardVisible = true
    private var photoImageHeightConstraint: Constraint?
    private let disposeBag = DisposeBag()
    private let cardWidth: CGFloat

    let swipeLeftRelay = PublishRelay<Void>()
    let swipeRightRelay = PublishRelay<Void>()
    let deleteButtonTappedRelay = PublishRelay<Void>()

    private let cardContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()

    private let frontCardView: UIView = {
        let view = UIView()
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

    private let photoImageView: AnimatedImageView = {
        let imageView = AnimatedImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 20
        return imageView
    }()

    private let deleteButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = UIColor.token(.backgroundPrimary).withAlphaComponent(0.9)
        button.layer.cornerRadius = 18
        button.clipsToBounds = true

        var config = UIButton.Configuration.plain()
        config.image = UIImage(named: "xmark")
        config.baseForegroundColor = .token(.textPrimary)
        config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)
        button.configuration = config

        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 4
        button.layer.shadowOpacity = 0.2

        return button
    }()

    private let overlayView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.token(.backgroundCard).withAlphaComponent(0.6)
        view.layer.cornerRadius = 20
        view.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        return view
    }()

    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = DesignToken.Typography.emphasis.numericFont
        label.textColor = .white
        return label
    }()

    private let locationLabel: UILabel = {
        let label = UILabel()
        label.font = .typography(.body)
        label.textColor = .white
        label.numberOfLines = 2
        return label
    }()

    private lazy var swipeHintLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("photo_detail.swipe_left_hint", comment: "")
        label.font = .typography(.caption)
        label.textColor = .white.withAlphaComponent(0.8)
        label.textAlignment = .right
        return label
    }()

    private let memoScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.backgroundColor = .clear
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        return scrollView
    }()

    private let memoLabel: UILabel = {
        let label = UILabel()
        label.font = .typography(.emphasis)
        label.textColor = .label
        label.numberOfLines = 0
        label.textAlignment = .left
        return label
    }()

    private lazy var backSwipeHintLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("photo_detail.swipe_right_hint", comment: "")
        label.font = .typography(.caption)
        label.textColor = .secondaryLabel
        label.textAlignment = .right
        return label
    }()

    init(cardWidth: CGFloat) {
        self.cardWidth = cardWidth
        super.init(frame: .zero)
        configureUI()
        setupGestures()
        setupActions()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureUI() {
        backgroundColor = .clear
        self.clipsToBounds = true

        addSubview(cardContainerView)
        cardContainerView.addSubview(frontCardView)
        cardContainerView.addSubview(backCardView)

        frontCardView.addSubview(photoImageView)
        frontCardView.addSubview(overlayView)
        frontCardView.addSubview(deleteButton)
        overlayView.addSubview(dateLabel)
        overlayView.addSubview(locationLabel)
        overlayView.addSubview(swipeHintLabel)

        backCardView.addSubview(memoScrollView)
        backCardView.addSubview(backSwipeHintLabel)
        memoScrollView.addSubview(memoLabel)

        cardContainerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
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
        }

        deleteButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.trailing.equalToSuperview().inset(8)
            make.width.height.equalTo(36)
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
            make.top.equalTo(locationLabel.snp.bottom).offset(4)
            make.trailing.equalToSuperview().inset(20)
            make.bottom.equalToSuperview().offset(-16)
        }

        memoScrollView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(40)
            make.horizontalEdges.equalToSuperview().inset(30)
            make.bottom.equalTo(backSwipeHintLabel.snp.top).offset(-20)
        }

        memoLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(memoScrollView.snp.width)
        }

        backSwipeHintLabel.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-20)
            make.trailing.equalToSuperview().inset(20)
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

    private func setupActions() {
        deleteButton.rx.tap
            .bind(to: deleteButtonTappedRelay)
            .disposed(by: disposeBag)
    }

    @objc private func handleSwipeLeft() {
        guard isFrontCardVisible else { return }
        swipeLeftRelay.accept(())
    }

    @objc private func handleSwipeRight() {
        guard !isFrontCardVisible else { return }
        swipeRightRelay.accept(())
    }

    func bind(
        photoImage: Driver<UIImage?>,
        dateText: Driver<String>,
        locationText: Driver<String>,
        memoText: Driver<String>,
        shouldFlipToBack: Observable<Void>,
        shouldFlipToFront: Observable<Void>
    ) {
        photoImage
            .drive(with: self) { owner, image in
                owner.photoImageView.image = image
                if let image = image {
                    let imageHeight = image.heightForWidth(owner.cardWidth)
                    let minimumHeight: CGFloat = 200
                    let finalHeight = max(imageHeight, minimumHeight)
                    owner.photoImageHeightConstraint?.update(offset: finalHeight)
                }
            }
            .disposed(by: disposeBag)

        dateText
            .drive(dateLabel.rx.text)
            .disposed(by: disposeBag)

        locationText
            .drive(locationLabel.rx.text)
            .disposed(by: disposeBag)

        memoText
            .drive(memoLabel.rx.text)
            .disposed(by: disposeBag)

        shouldFlipToBack
            .bind(with: self) { owner, _ in
                owner.flipToBack()
            }
            .disposed(by: disposeBag)

        shouldFlipToFront
            .bind(with: self) { owner, _ in
                owner.flipToFront()
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
}
