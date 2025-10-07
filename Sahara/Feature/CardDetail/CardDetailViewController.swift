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
    private let sourceType: EditSourceType

    private let viewDidLoadRelay = PublishRelay<Void>()
    private let swipeLeftRelay = PublishRelay<Void>()
    private let swipeRightRelay = PublishRelay<Void>()
    private let deleteConfirmedRelay = PublishRelay<Void>()
    private var photoImageHeightConstraint: Constraint?

    private let customNavigationBar = CustomNavigationBar()

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
        view.backgroundColor = ColorSystem.cardBackground.withAlphaComponent(0.6)
        view.layer.cornerRadius = 20
        view.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        return view
    }()

    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = FontSystem.galmuriMono(size: 18)
        label.textColor = .white
        return label
    }()

    private let locationLabel: UILabel = {
        let label = UILabel()
        label.font = FontSystem.galmuriMono(size: 14)
        label.textColor = .white
        label.numberOfLines = 2
        return label
    }()

    private lazy var swipeHintLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("photo_detail.swipe_left_hint", comment: "")
        label.font = FontSystem.galmuriMono(size: 12)
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
        label.font = FontSystem.galmuriMono(size: 18)
        label.textColor = .label
        label.numberOfLines = 0
        label.textAlignment = .left
        return label
    }()

    private lazy var backSwipeHintLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("photo_detail.swipe_right_hint", comment: "")
        label.font = FontSystem.galmuriMono(size: 12)
        label.textColor = .secondaryLabel
        label.textAlignment = .right
        return label
    }()


    private let buttonContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()

    private lazy var saveButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .white
        button.layer.cornerRadius = 35
        button.clipsToBounds = true

        let font = FontSystem.galmuriMono(size: 12)
        let title = NSLocalizedString("common.save", comment: "")
        button.setAttributedTitle(title.attributedString(font: font, letterSpacing: -6, color: .black), for: .normal)

        return button
    }()

    private lazy var shareButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .white
        button.layer.cornerRadius = 35
        button.clipsToBounds = true

        let font = FontSystem.galmuriMono(size: 12)
        let title = NSLocalizedString("common.share", comment: "")
        button.setAttributedTitle(title.attributedString(font: font, letterSpacing: -6, color: .black), for: .normal)

        return button
    }()


    init(cardId: ObjectId, sourceType: EditSourceType = .dateView) {
        self.viewModel = CardDetailViewModel(cardId: cardId)
        self.sourceType = sourceType
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        navigationController?.interactivePopGestureRecognizer?.delegate = nil
        setupCustomNavigationBar()
        configureUI()
        setupGestures()
        bind()
        viewDidLoadRelay.accept(())
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewDidLoadRelay.accept(())
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        saveButton.applyGradient(.saveShareButton)
        shareButton.applyGradient(.saveShareButton)
    }

    private func setupCustomNavigationBar() {
        customNavigationBar.configure(title: NSLocalizedString("card_detail.title", comment: ""))

        if navigationController != nil && presentingViewController == nil {
            customNavigationBar.setLeftButtonImage(UIImage(named: "chevronLeft"))
            customNavigationBar.onLeftButtonTapped = { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            }
        } else {
            customNavigationBar.setLeftButtonImage(UIImage(systemName: "xmark"))
            customNavigationBar.onLeftButtonTapped = { [weak self] in
                self?.dismiss(animated: true)
            }
        }

        customNavigationBar.addRightButton(image: UIImage(named: "editBox"), tintColor: .black) { [weak self] in
            self?.openEditView()
        }
    }

    private func configureUI() {
        view.applyGradientWithDots(.pinkBlue, dotSize: 5, spacing: 32, dotColor: .white)

        view.addSubview(customNavigationBar)
        view.addSubview(cardContainerView)
        view.addSubview(buttonContainerView)

        cardContainerView.addSubview(frontCardView)
        cardContainerView.addSubview(backCardView)

        frontCardView.addSubview(photoImageView)
        frontCardView.addSubview(overlayView)
        overlayView.addSubview(dateLabel)
        overlayView.addSubview(locationLabel)
        overlayView.addSubview(swipeHintLabel)

        backCardView.addSubview(memoScrollView)
        backCardView.addSubview(backSwipeHintLabel)
        memoScrollView.addSubview(memoLabel)

        buttonContainerView.addSubview(saveButton)
        buttonContainerView.addSubview(shareButton)

        customNavigationBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.horizontalEdges.equalToSuperview()
            make.height.equalTo(54)
        }

        cardContainerView.snp.makeConstraints { make in
            make.top.equalTo(customNavigationBar.snp.bottom).offset(32)
            make.horizontalEdges.equalToSuperview().inset(32)
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

        buttonContainerView.snp.makeConstraints { make in
            make.top.equalTo(cardContainerView.snp.bottom).offset(32)
            make.centerX.equalToSuperview()
            make.height.equalTo(70)
        }

        saveButton.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.centerY.equalToSuperview()
            make.width.height.equalTo(70)
        }

        shareButton.snp.makeConstraints { make in
            make.leading.equalTo(saveButton.snp.trailing).offset(12)
            make.trailing.equalToSuperview()
            make.centerY.equalToSuperview()
            make.width.height.equalTo(70)
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

    private func showDeleteAlert() {
        let alert = UIAlertController(
            title: NSLocalizedString("card_detail.delete_title", comment: ""),
            message: NSLocalizedString("card_detail.delete_message", comment: ""),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: NSLocalizedString("card_detail.delete_cancel", comment: ""), style: .cancel))
        alert.addAction(UIAlertAction(title: NSLocalizedString("card_detail.delete_confirm", comment: ""), style: .destructive) { [weak self] _ in
            self?.deleteConfirmedRelay.accept(())
        })
        present(alert, animated: true)
    }

    private func openEditView() {
        guard let card = viewModel.getCard() else { return }
        let editViewModel = CardInfoViewModel(cardToEdit: card, sourceType: sourceType)
        let editVC = CardInfoViewController(viewModel: editViewModel)
        editVC.modalPresentationStyle = .fullScreen
        present(editVC, animated: true)
    }

    private func bind() {
        let input = CardDetailViewModel.Input(
            viewDidLoad: viewDidLoadRelay.asObservable(),
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

        output.saveResult
            .drive(with: self) { owner, result in
                switch result {
                case .success:
                    let message = NSLocalizedString("photo_detail.save_success_message", comment: "")
                    owner.showToast(message: message)
                case .failure(let error):
                    owner.showToast(message: error.localizedDescription)
                }
            }
            .disposed(by: disposeBag)

        output.shareImage
            .drive(with: self) { owner, image in
                let itemSource = ShareActivityItemSource(image: image)
                let activityVC = UIActivityViewController(activityItems: [itemSource], applicationActivities: nil)
                activityVC.popoverPresentationController?.sourceView = owner.shareButton
                owner.present(activityVC, animated: true)
            }
            .disposed(by: disposeBag)

        output.deleteCompleted
            .drive(with: self) { owner, _ in
                NotificationCenter.default.post(name: AppNotification.photoDeleted.name, object: nil)
                if owner.navigationController != nil && owner.presentingViewController == nil {
                    owner.navigationController?.popViewController(animated: true)
                } else {
                    owner.dismiss(animated: true)
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
        let imageWidth = view.frame.width - 64
        let imageHeight = image.heightForWidth(imageWidth)

        photoImageHeightConstraint?.update(offset: imageHeight)
        view.layoutIfNeeded()
    }
}
