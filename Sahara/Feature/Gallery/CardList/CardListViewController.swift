//
//  CardListViewController.swift
//  Sahara
//
//  Created by 금가경 on 10/1/25.
//

import RealmSwift
import RxCocoa
import RxSwift
import SnapKit
import UIKit

final class CardListViewController: UIViewController {
    private let viewModel: CardListViewModel
    private let disposeBag = DisposeBag()
    private let viewDidLoadRelay = PublishRelay<Void>()

    private let customNavigationBar = CustomNavigationBar()

    private let closeButton: UIButton = {
        let button = UIButton()
        var config = UIButton.Configuration.plain()
        config.image = UIImage(named: "chevronLeft")
        config.baseForegroundColor = .black
        button.configuration = config
        return button
    }()

    private var pinterestLayout: PinterestLayout!

    private lazy var collectionView: UICollectionView = {
        pinterestLayout = PinterestLayout()
        pinterestLayout.delegate = self

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: pinterestLayout)
        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.register(CardListCell.self, forCellWithReuseIdentifier: CardListCell.identifier)
        return collectionView
    }()

    private let themeCategory: ThemeCategory
    private let customTitle: String?

    init(cards: [Card], themeCategory: ThemeCategory, customTitle: String? = nil) {
        self.viewModel = CardListViewModel(cards: cards)
        self.themeCategory = themeCategory
        self.customTitle = customTitle
        super.init(nibName: nil, bundle: nil)
    }

    init(folderName: String) {
        self.viewModel = CardListViewModel(folderName: folderName)
        self.themeCategory = .others
        self.customTitle = folderName
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
        viewDidLoadRelay.accept(())
    }

    private func setupCustomNavigationBar() {
        let title = customTitle ?? themeCategory.localizedName
        customNavigationBar.configure(title: title)
        customNavigationBar.hideLeftButton()

        view.addSubview(closeButton)

        closeButton.snp.makeConstraints { make in
            make.leading.equalTo(customNavigationBar).offset(8)
            make.centerY.equalTo(customNavigationBar)
            make.width.equalTo(44)
            make.height.equalTo(44)
        }
    }

    private func configureUI() {
        view.applyGradientWithDots(.pinkBlue, dotSize: 5, spacing: 32, dotColor: .white)

        view.addSubview(customNavigationBar)
        view.addSubview(collectionView)

        customNavigationBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.horizontalEdges.equalToSuperview()
            make.height.equalTo(54)
        }

        collectionView.snp.makeConstraints { make in
            make.top.equalTo(customNavigationBar.snp.bottom).offset(24)
            make.horizontalEdges.equalToSuperview().inset(24)
            make.bottom.equalTo(view.safeAreaLayoutGuide)
        }
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 80, right: 0)
    }

    private func bind() {
        let input = CardListViewModel.Input(
            viewDidLoad: viewDidLoadRelay.asObservable(),
            itemSelected: collectionView.rx.itemSelected.asObservable(),
            closeButtonTapped: closeButton.rx.tap.asObservable()
        )

        let output = viewModel.transform(input: input)

        output.cards
            .drive(collectionView.rx.items(cellIdentifier: CardListCell.identifier, cellType: CardListCell.self)) { _, card, cell in
                cell.configure(with: card)
            }
            .disposed(by: disposeBag)

        output.navigateToDetail
            .drive(with: self) { owner, cardId in
                let sourceType: EditSourceType = owner.themeCategory == .others ? .locationView : .themeView
                guard let card = owner.viewModel.getCard(by: cardId) else { return }

                if card.isLocked {
                    BiometricAuthManager.shared.authenticate { success, error in
                        if success {
                            let detailVC = CardDetailViewController(cardId: cardId, sourceType: sourceType)
                            owner.navigationController?.pushViewController(detailVC, animated: true)
                        } else {
                            if let error = error {
                                owner.showToast(message: error.localizedDescription)
                            }
                        }
                    }
                } else {
                    let detailVC = CardDetailViewController(cardId: cardId, sourceType: sourceType)
                    owner.navigationController?.pushViewController(detailVC, animated: true)
                }
            }
            .disposed(by: disposeBag)

        output.dismiss
            .drive(with: self) { owner, _ in
                owner.navigationController?.popViewController(animated: true)
            }
            .disposed(by: disposeBag)
    }
}

extension CardListViewController: PinterestLayoutDelegate {
    func collectionView(_ collectionView: UICollectionView, heightForPhotoAtIndexPath indexPath: IndexPath) -> CGFloat {
        guard let cell = viewModel.getCard(at: indexPath.item),
              let image = UIImage(data: cell.editedImageData) else {
            return 180
        }

        let aspectRatio = image.size.height / image.size.width
        let cellWidth = (collectionView.bounds.width - 8) / 2
        return cellWidth * aspectRatio
    }
}
