//
//  CalendarViewController.swift
//  Sahara
//
//  Created by 금가경 on 10/2/25.
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit
import UniformTypeIdentifiers

final class CalendarViewController: UIViewController {
    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        collectionView.register(CalendarCell.self, forCellWithReuseIdentifier: CalendarCell.identifier)
        collectionView.register(
            CalendarHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: CalendarHeaderView.identifier
        )
        collectionView.applyGlassCardStyle()
        collectionView.isScrollEnabled = false
        return collectionView
    }()

    private let viewModel: GalleryViewModel
    private let disposeBag = DisposeBag()
    private let previousMonthRelay = PublishRelay<Void>()
    private let nextMonthRelay = PublishRelay<Void>()
    private var currentHeaderView: CalendarHeaderView?
    private lazy var dataSource = makeDataSource()
    #if targetEnvironment(macCatalyst)
    private weak var highlightedCell: CalendarCell?
    #endif

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
        #if targetEnvironment(macCatalyst)
        setupDropInteraction()
        #endif
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

    private func makeDataSource() -> UICollectionViewDiffableDataSource<Int, DayItem> {
        let ds = UICollectionViewDiffableDataSource<Int, DayItem>(
            collectionView: collectionView
        ) { collectionView, indexPath, item in
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: CalendarCell.identifier,
                for: indexPath
            ) as? CalendarCell else {
                return UICollectionViewCell()
            }
            cell.configure(with: item)
            return cell
        }

        ds.supplementaryViewProvider = { [weak self] collectionView, kind, indexPath in
            guard let self,
                  kind == UICollectionView.elementKindSectionHeader,
                  let header = collectionView.dequeueReusableSupplementaryView(
                      ofKind: kind,
                      withReuseIdentifier: CalendarHeaderView.identifier,
                      for: indexPath
                  ) as? CalendarHeaderView else {
                return UICollectionReusableView()
            }
            self.currentHeaderView = header
            let formatter = DateFormatter()
            formatter.locale = Locale.current
            formatter.dateFormat = NSLocalizedString("gallery.month_format", comment: "")
            header.configure(monthTitle: formatter.string(from: Date()))
            header.onPreviousMonthTapped = { [weak self] in self?.previousMonthRelay.accept(()) }
            header.onNextMonthTapped = { [weak self] in self?.nextMonthRelay.accept(()) }
            return header
        }

        return ds
    }

    private func bind() {
        let input = GalleryViewModel.Input(
            addButtonTapped: Observable.never(),
            previousMonthTapped: previousMonthRelay.asObservable(),
            nextMonthTapped: nextMonthRelay.asObservable(),
            viewTypeSelected: Observable.just(.date)
        )

        let output = viewModel.transform(input: input)

        output.calendarItems
            .drive(with: self) { owner, items in
                owner.applySnapshot(items: items)
            }
            .disposed(by: disposeBag)

        output.currentMonthTitle
            .drive(with: self) { owner, monthTitle in
                owner.currentHeaderView?.configure(monthTitle: monthTitle)
            }
            .disposed(by: disposeBag)

        collectionView.rx.itemSelected
            .compactMap { [weak self] indexPath in self?.dataSource.itemIdentifier(for: indexPath) }
            .bind(with: self) { owner, item in
                guard let date = item.date else { return }

                if item.hasCards {
                    let detailVC = CardListViewController(date: date)
                    if let galleryVC = owner.parent as? GalleryViewController {
                        galleryVC.navigationController?.pushViewController(detailVC, animated: true)
                    }
                } else {
                    let viewModel = CardInfoViewModel(initialDate: date, sourceType: .dateView)
                    if let galleryVC = owner.parent as? GalleryViewController {
                        let coordinator = CardInfoCoordinator(parentViewController: galleryVC)
                        let cardInfoVC = CardInfoViewController(viewModel: viewModel, coordinator: coordinator)
                        coordinator.cardInfoViewController = cardInfoVC
                        let navController = UINavigationController(rootViewController: cardInfoVC)
                        navController.modalPresentationStyle = .fullScreen
                        galleryVC.present(navController, animated: true)
                    }
                }
            }
            .disposed(by: disposeBag)
    }

    private func applySnapshot(items: [DayItem]) {
        let oldItems = dataSource.snapshot().itemIdentifiers
        let oldMap = Dictionary(uniqueKeysWithValues: oldItems.map { ($0, $0.cards) })

        var snapshot = NSDiffableDataSourceSnapshot<Int, DayItem>()
        snapshot.appendSections([0])
        snapshot.appendItems(items)

        let toReconfigure = items.filter { item in
            guard let oldCards = oldMap[item] else { return false }
            return oldCards != item.cards
        }
        snapshot.reconfigureItems(toReconfigure)

        dataSource.apply(snapshot, animatingDifferences: false)
    }

    private func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 1
        layout.minimumLineSpacing = 1
        let sectionTopInset: CGFloat = 8
        layout.sectionInset = UIEdgeInsets(top: sectionTopInset, left: 0, bottom: 0, right: 0)

        let headerHeight: CGFloat = 72
        layout.headerReferenceSize = CGSize(width: collectionView.bounds.width, height: headerHeight)

        let collectionViewWidth = collectionView.bounds.width
        let itemWidth = ((collectionViewWidth - 6) / 7).rounded(.down)

        let collectionViewHeight = collectionView.bounds.height - headerHeight - sectionTopInset
        let itemHeight = ((collectionViewHeight - 5) / 6).rounded(.down)

        layout.itemSize = CGSize(width: itemWidth, height: itemHeight)

        return layout
    }
}

#if targetEnvironment(macCatalyst)
extension CalendarViewController: UICollectionViewDropDelegate {
    func setupDropInteraction() {
        collectionView.dropDelegate = self
    }

    func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool {
        session.canLoadObjects(ofClass: UIImage.self)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        dropSessionDidUpdate session: UIDropSession,
        withDestinationIndexPath destinationIndexPath: IndexPath?
    ) -> UICollectionViewDropProposal {
        let point = session.location(in: collectionView)

        guard let indexPath = collectionView.indexPathForItem(at: point),
              let item = dataSource.itemIdentifier(for: indexPath),
              item.date != nil else {
            clearDropHighlight()
            return UICollectionViewDropProposal(operation: .cancel)
        }

        if let cell = collectionView.cellForItem(at: indexPath) as? CalendarCell, cell !== highlightedCell {
            highlightedCell?.setDropHighlight(false)
            cell.setDropHighlight(true)
            highlightedCell = cell
        }

        return UICollectionViewDropProposal(operation: .copy)
    }

    func collectionView(_ collectionView: UICollectionView, dropSessionDidExit session: UIDropSession) {
        clearDropHighlight()
    }

    func collectionView(_ collectionView: UICollectionView, dropSessionDidEnd session: UIDropSession) {
        clearDropHighlight()
    }

    func collectionView(
        _ collectionView: UICollectionView,
        performDropWith coordinator: UICollectionViewDropCoordinator
    ) {
        clearDropHighlight()

        let session = coordinator.session
        let point = session.location(in: collectionView)
        guard let indexPath = collectionView.indexPathForItem(at: point),
              let date = dataSource.itemIdentifier(for: indexPath)?.date else { return }

        guard let item = session.items.first else { return }
        let provider = item.itemProvider

        let imageType = provider.registeredTypeIdentifiers
            .compactMap { UTType($0) }
            .first { $0.conforms(to: .image) }
            ?? .image

        _ = provider.loadDataRepresentation(for: imageType) { [weak self] data, _ in
            DispatchQueue.main.async {
                guard let self else { return }

                if let data, let result = ImageFormatConverter.createImageSourceData(from: data) {
                    self.presentCardInfo(date: date, imageResult: result)
                } else {
                    self.loadDroppedImageFallback(from: session, date: date)
                }
            }
        }
    }

    private func clearDropHighlight() {
        highlightedCell?.setDropHighlight(false)
        highlightedCell = nil
    }

    private func presentCardInfo(date: Date, imageResult: ImageFormatConverter.ImageSourceResult) {
        guard let galleryVC = parent as? GalleryViewController else { return }

        let viewModel = CardInfoViewModel(initialDate: date, sourceType: .dateView)
        let coordinator = CardInfoCoordinator(parentViewController: galleryVC)
        let cardInfoVC = CardInfoViewController(viewModel: viewModel, coordinator: coordinator)
        coordinator.cardInfoViewController = cardInfoVC

        let navController = UINavigationController(rootViewController: cardInfoVC)
        navController.modalPresentationStyle = .fullScreen
        galleryVC.present(navController, animated: true) {
            cardInfoVC.applyDroppedImage(result: imageResult)
        }
    }

    private func loadDroppedImageFallback(from session: UIDropSession, date: Date) {
        _ = session.loadObjects(ofClass: UIImage.self) { [weak self] images in
            guard let image = images.first as? UIImage else { return }
            DispatchQueue.main.async {
                guard let self else { return }

                let imageSource = ImageSourceData(image: image)
                let result = ImageFormatConverter.ImageSourceResult(
                    imageSource: imageSource,
                    metadata: .init(location: nil, date: nil)
                )
                self.presentCardInfo(date: date, imageResult: result)
            }
        }
    }
}
#endif
