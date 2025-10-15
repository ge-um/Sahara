//
//  CalendarViewController.swift
//  Sahara
//
//  Created by 금가경 on 10/2/25.
//

import UIKit
import RxSwift
import RxCocoa
import RxDataSources
import SnapKit

final class CalendarViewController: UIViewController {
    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        collectionView.register(CalendarCell.self, forCellWithReuseIdentifier: CalendarCell.identifier)
        collectionView.register(
            CalendarHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: CalendarHeaderView.identifier
        )
        collectionView.backgroundColor = ColorSystem.white30
        collectionView.isScrollEnabled = false
        collectionView.layer.cornerRadius = 12
        collectionView.clipsToBounds = true
        return collectionView
    }()

    private let viewModel: GalleryViewModel
    private let disposeBag = DisposeBag()
    private let previousMonthRelay = PublishRelay<Void>()
    private let nextMonthRelay = PublishRelay<Void>()
    private var currentHeaderView: CalendarHeaderView?

    init(viewModel: GalleryViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        bind()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if collectionView.collectionViewLayout is UICollectionViewFlowLayout {
            collectionView.collectionViewLayout = createLayout()
        }
    }

    private func configureUI() {
        view.addSubview(collectionView)

        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        setupSwipeGestures()
    }

    private func setupSwipeGestures() {
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeLeft))
        swipeLeft.direction = .left
        collectionView.addGestureRecognizer(swipeLeft)

        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeRight))
        swipeRight.direction = .right
        collectionView.addGestureRecognizer(swipeRight)
    }

    @objc private func handleSwipeLeft() {
        nextMonthRelay.accept(())
    }

    @objc private func handleSwipeRight() {
        previousMonthRelay.accept(())
    }

    private func bind() {
        let input = GalleryViewModel.Input(
            addButtonTapped: Observable.never(),
            previousMonthTapped: previousMonthRelay.asObservable(),
            nextMonthTapped: nextMonthRelay.asObservable(),
            viewTypeSelected: Observable.just(.date)
        )

        let output = viewModel.transform(input: input)

        let dataSource = RxCollectionViewSectionedReloadDataSource<CalendarSection>(
            configureCell: { _, collectionView, indexPath, item in
                guard let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: CalendarCell.identifier,
                    for: indexPath
                ) as? CalendarCell else {
                    return UICollectionViewCell()
                }
                cell.configure(with: item)
                return cell
            },
            configureSupplementaryView: { [weak self] _, collectionView, kind, indexPath in
                guard let self = self,
                      kind == UICollectionView.elementKindSectionHeader,
                      let header = collectionView.dequeueReusableSupplementaryView(
                        ofKind: kind,
                        withReuseIdentifier: CalendarHeaderView.identifier,
                        for: indexPath
                      ) as? CalendarHeaderView else {
                    return UICollectionReusableView()
                }

                self.currentHeaderView = header
                header.onPreviousMonthTapped = { [weak self] in
                    self?.previousMonthRelay.accept(())
                }
                header.onNextMonthTapped = { [weak self] in
                    self?.nextMonthRelay.accept(())
                }

                return header
            }
        )

        output.calendarItems
            .map { [CalendarSection(items: $0)] }
            .drive(collectionView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)

        output.currentMonthTitle
            .drive(with: self) { owner, monthTitle in
                owner.currentHeaderView?.configure(monthTitle: monthTitle)
            }
            .disposed(by: disposeBag)

        collectionView.rx.modelSelected(DayItem.self)
            .bind(with: self) { owner, item in
                guard let date = item.date else { return }

                if item.hasCards {
                    let detailVC = CardListViewController(date: date)
                    if let galleryVC = owner.parent as? GalleryViewController {
                        galleryVC.navigationController?.pushViewController(detailVC, animated: true)
                    }
                } else {
                    let viewModel = CardInfoViewModel(initialDate: date, sourceType: .dateView)
                    let cardInfoVC = CardInfoViewController(viewModel: viewModel)
                    let navController = UINavigationController(rootViewController: cardInfoVC)
                    navController.modalPresentationStyle = .fullScreen
                    if let galleryVC = owner.parent as? GalleryViewController {
                        galleryVC.present(navController, animated: true)
                    }
                }
            }
            .disposed(by: disposeBag)
    }

    private func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 1
        layout.minimumLineSpacing = 1
        layout.sectionInset = .zero

        let headerHeight: CGFloat = 72
        layout.headerReferenceSize = CGSize(width: collectionView.bounds.width, height: headerHeight)

        let collectionViewWidth = collectionView.bounds.width
        let itemWidth = ((collectionViewWidth - 6) / 7).rounded(.down)

        let collectionViewHeight = collectionView.bounds.height - headerHeight
        let itemHeight = ((collectionViewHeight - 5) / 6).rounded(.down)

        layout.itemSize = CGSize(width: itemWidth, height: itemHeight)

        return layout
    }
}
