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
    enum NavigationType {
        case close
        case back
    }

    private let viewModel: any BaseViewModelProtocol
    private let navigationType: NavigationType
    private let sourceType: EditSourceType
    private let disposeBag = DisposeBag()

    private let customNavigationBar = CustomNavigationBar()

    private lazy var closeButton: UIButton = {
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
        collectionView.register(CardThumbnailCell.self, forCellWithReuseIdentifier: CardThumbnailCell.identifier)
        return collectionView
    }()

    private lazy var dataSource: UICollectionViewDiffableDataSource<Int, ObjectId>? = {
        guard viewModel is CalendarDetailViewModel else { return nil }
        return UICollectionViewDiffableDataSource<Int, ObjectId>(collectionView: collectionView) { [weak self] collectionView, indexPath, cardId in
            guard let self = self,
                  let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: CardThumbnailCell.identifier,
                for: indexPath
            ) as? CardThumbnailCell,
                  let card = self.getCard(by: cardId) else {
                return UICollectionViewCell()
            }
            cell.configure(with: card)
            return cell
        }
    }()

    private let navigationTitle: String

    init(cardIds: [ObjectId], themeCategory: ThemeCategory, customTitle: String? = nil) {
        self.viewModel = CardListViewModel(cardIds: cardIds)
        self.navigationType = .close
        self.sourceType = themeCategory == .others ? .locationView : .themeView
        self.navigationTitle = customTitle ?? themeCategory.localizedName
        super.init(nibName: nil, bundle: nil)
    }

    init(folderName: String) {
        self.viewModel = CardListViewModel(folderName: folderName)
        self.navigationType = .close
        self.sourceType = .locationView
        self.navigationTitle = folderName
        super.init(nibName: nil, bundle: nil)
    }

    init(date: Date) {
        self.viewModel = CalendarDetailViewModel(date: date)
        self.navigationType = .back
        self.sourceType = .dateView

        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "yyyyMMMMd", options: 0, locale: Locale.current)
        self.navigationTitle = formatter.string(from: date)

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
    }

    private func setupCustomNavigationBar() {
        customNavigationBar.configure(title: navigationTitle)

        switch navigationType {
        case .close:
            customNavigationBar.hideLeftButton()
            view.addSubview(closeButton)

            closeButton.snp.makeConstraints { make in
                make.leading.equalTo(customNavigationBar).offset(8)
                make.centerY.equalTo(customNavigationBar)
                make.width.equalTo(44)
                make.height.equalTo(44)
            }
        case .back:
            customNavigationBar.onLeftButtonTapped = { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            }
        }
    }

    private func configureUI() {
        view.applyGradientWithDots(.primary, dotSize: 5, spacing: 32, dotColor: .token(.textOnAccent))

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
        if let cardListVM = viewModel as? CardListViewModel {
            bindCardListViewModel(cardListVM)
        } else if let calendarDetailVM = viewModel as? CalendarDetailViewModel {
            bindCalendarDetailViewModel(calendarDetailVM)
        }
    }

    private func bindCardListViewModel(_ viewModel: CardListViewModel) {
        let input = CardListViewModel.Input(
            itemSelected: collectionView.rx.itemSelected.asObservable(),
            closeButtonTapped: closeButton.rx.tap.asObservable()
        )

        let output = viewModel.transform(input: input)

        output.cards
            .drive(collectionView.rx.items(cellIdentifier: CardThumbnailCell.identifier, cellType: CardThumbnailCell.self)) { _, item, cell in
                cell.configure(with: item)
            }
            .disposed(by: disposeBag)

        output.navigateToDetail
            .drive(with: self) { owner, cardId in
                owner.navigateToDetail(cardId: cardId)
            }
            .disposed(by: disposeBag)

        output.dismiss
            .drive(with: self) { owner, _ in
                owner.navigationController?.popViewController(animated: true)
            }
            .disposed(by: disposeBag)
    }

    private func bindCalendarDetailViewModel(_ viewModel: CalendarDetailViewModel) {
        let input = CalendarDetailViewModel.Input(
            itemSelected: collectionView.rx.itemSelected.asObservable(),
            itemDeleted: Observable.never()
        )

        let output = viewModel.transform(input: input)

        output.shouldPopIfEmpty
            .drive(with: self) { owner, shouldPop in
                if shouldPop {
                    owner.navigationController?.popViewController(animated: true)
                }
            }
            .disposed(by: disposeBag)

        output.cardIds
            .drive(with: self) { owner, cardIds in
                guard let dataSource = owner.dataSource else { return }
                var snapshot = NSDiffableDataSourceSnapshot<Int, ObjectId>()
                snapshot.appendSections([0])
                snapshot.appendItems(cardIds)
                let existing = Set(dataSource.snapshot().itemIdentifiers)
                let toReconfigure = cardIds.filter { existing.contains($0) }
                snapshot.reconfigureItems(toReconfigure)
                dataSource.apply(snapshot, animatingDifferences: true) {
                    owner.pinterestLayout.invalidateLayout()
                }
            }
            .disposed(by: disposeBag)

        output.navigateToDetail
            .drive(with: self) { owner, cardId in
                owner.navigateToDetail(cardId: cardId)
            }
            .disposed(by: disposeBag)
    }

    private func navigateToDetail(cardId: ObjectId) {
        guard let item = getCard(by: cardId) else { return }

        if item.isLocked {
            BiometricAuthService.shared.authenticate { [weak self] success, error in
                guard let self = self else { return }
                if success {
                    let detailVC = CardDetailViewController(cardId: cardId, sourceType: self.sourceType)
                    self.navigationController?.pushViewController(detailVC, animated: true)
                } else {
                    if let error = error as NSError? {
                        if error.domain == "BiometricPermissionError" {
                            self.showBiometricPermissionAlert()
                        } else {
                            self.showToast(message: error.localizedDescription)
                        }
                    }
                }
            }
        } else {
            let detailVC = CardDetailViewController(cardId: cardId, sourceType: sourceType)
            navigationController?.pushViewController(detailVC, animated: true)
        }
    }

    private func getCard(by id: ObjectId) -> CardListItemDTO? {
        if let cardListVM = viewModel as? CardListViewModel {
            return cardListVM.getCard(by: id)
        } else if let calendarDetailVM = viewModel as? CalendarDetailViewModel {
            return calendarDetailVM.getCard(by: id)
        }
        return nil
    }

    private func getCard(at index: Int) -> CardListItemDTO? {
        if let cardListVM = viewModel as? CardListViewModel {
            return cardListVM.getCard(at: index)
        }
        return nil
    }
}

extension CardListViewController: PinterestLayoutDelegate {
    func collectionView(_ collectionView: UICollectionView, heightForPhotoAtIndexPath indexPath: IndexPath) -> CGFloat {
        let item: CardListItemDTO?

        if let cardListVM = viewModel as? CardListViewModel {
            item = cardListVM.getCard(at: indexPath.item)
        } else if let calendarDetailVM = viewModel as? CalendarDetailViewModel, let dataSource = dataSource {
            guard let cardId = dataSource.itemIdentifier(for: indexPath) else {
                return 180
            }
            item = calendarDetailVM.getCard(by: cardId)
        } else {
            return 180
        }

        guard let item = item,
              let aspectRatio = ThumbnailCache.shared.aspectRatio(for: item.id) else {
            return 180
        }

        let columnWidth = collectionView.bounds.width / CGFloat(pinterestLayout.columnCount)
        let calculatedHeight = columnWidth * aspectRatio

        return calculatedHeight.isFinite && calculatedHeight > 0 ? calculatedHeight : 180
    }
}
