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
    private let sourceType: EditSourceType

    private let viewDidLoadRelay = PublishRelay<Void>()
    private let deleteConfirmedRelay = PublishRelay<Void>()

    private let customNavigationBar = CustomNavigationBar()

    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.backgroundColor = .clear
        return scrollView
    }()

    private let contentView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()

    private let photoCardView = PhotoCardView()

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
        view.addSubview(scrollView)

        scrollView.addSubview(contentView)
        contentView.addSubview(photoCardView)
        contentView.addSubview(buttonContainerView)

        buttonContainerView.addSubview(saveButton)
        buttonContainerView.addSubview(shareButton)

        customNavigationBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.horizontalEdges.equalToSuperview()
            make.height.equalTo(54)
        }

        scrollView.snp.makeConstraints { make in
            make.top.equalTo(customNavigationBar.snp.bottom)
            make.horizontalEdges.bottom.equalToSuperview()
        }

        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(scrollView.snp.width)
        }

        photoCardView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(32)
            make.horizontalEdges.equalToSuperview().inset(32)
        }

        buttonContainerView.snp.makeConstraints { make in
            make.top.equalTo(photoCardView.snp.bottom).offset(32)
            make.centerX.equalToSuperview()
            make.height.equalTo(70)
            make.bottom.equalToSuperview().offset(-88)
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
            swipeLeft: photoCardView.swipeLeftRelay.asObservable(),
            swipeRight: photoCardView.swipeRightRelay.asObservable()
        )

        let output = viewModel.transform(input: input)

        Driver.combineLatest(
            output.photoImage,
            output.dateText,
            output.locationText,
            output.memoText
        )
        .drive(with: self) { owner, data in
            let (image, date, location, memo) = data
            owner.photoCardView.configure(image: image, date: date, location: location, memo: memo)
        }
        .disposed(by: disposeBag)

        output.shouldFlipToBack
            .drive(with: self) { owner, _ in
                owner.photoCardView.flipToBack()
            }
            .disposed(by: disposeBag)

        output.shouldFlipToFront
            .drive(with: self) { owner, _ in
                owner.photoCardView.flipToFront()
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
}
