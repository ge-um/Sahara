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
    private let calendarContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.layer.cornerRadius = 12
        view.clipsToBounds = true
        return view
    }()

    private let calendarHeaderView = CalendarHeaderView()

    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout())
        collectionView.register(CalendarCell.self, forCellWithReuseIdentifier: CalendarCell.identifier)
        collectionView.backgroundColor = .clear
        collectionView.isScrollEnabled = false
        return collectionView
    }()

    private let viewModel: GalleryViewModel
    private let disposeBag = DisposeBag()
    private let previousMonthRelay = PublishRelay<Void>()
    private let nextMonthRelay = PublishRelay<Void>()

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

    private func configureUI() {
        view.addSubview(calendarContainerView)
        calendarContainerView.addSubview(calendarHeaderView)
        calendarContainerView.addSubview(collectionView)

        calendarContainerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        calendarHeaderView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.horizontalEdges.equalToSuperview()
            make.height.equalTo(72)
        }

        collectionView.snp.makeConstraints { make in
            make.top.equalTo(calendarHeaderView.snp.bottom)
            make.horizontalEdges.equalToSuperview()
            make.bottom.equalToSuperview()
        }
    }

    private func bind() {
        calendarHeaderView.onPreviousMonthTapped = { [weak self] in
            self?.previousMonthRelay.accept(())
        }

        calendarHeaderView.onNextMonthTapped = { [weak self] in
            self?.nextMonthRelay.accept(())
        }

        let input = GalleryViewModel.Input(
            viewWillAppear: rx.methodInvoked(#selector(viewWillAppear(_:))).map { _ in () },
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
            }
        )

        output.calendarItems
            .map { [CalendarSection(items: $0)] }
            .drive(collectionView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)

        output.currentMonthTitle
            .drive(with: self) { owner, monthTitle in
                owner.calendarHeaderView.configure(monthTitle: monthTitle)
            }
            .disposed(by: disposeBag)

        collectionView.rx.modelSelected(DayItem.self)
            .filter { $0.hasCards }
            .compactMap { $0.date }
            .bind(with: self) { owner, date in
                let detailVC = CalendarDetailViewController(date: date)
                if let galleryVC = owner.parent as? GalleryViewController {
                    galleryVC.navigationController?.pushViewController(detailVC, animated: true)
                }
            }
            .disposed(by: disposeBag)
    }

    private func layout() -> UICollectionViewLayout {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        layout.sectionInset = .zero

        let collectionViewWidth = UIScreen.main.bounds.width - 40
        let itemWidth = floor(collectionViewWidth / 7)

        let topHeight: CGFloat = 54 + 20 + 36 + 10 + 68
        let availableHeight = UIScreen.main.bounds.height - topHeight - 90
        let itemHeight = floor(availableHeight / 6)

        layout.itemSize = CGSize(width: itemWidth, height: itemHeight)

        return layout
    }
}
