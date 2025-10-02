//
//  CalendarDetailViewController.swift
//  Sahara
//
//  Created by 금가경 on 9/29/25.
//

import RxCocoa
import RxSwift
import SnapKit
import UIKit

final class CalendarDetailViewController: UIViewController {
    private let viewModel: CalendarDetailViewModel
    private let disposeBag = DisposeBag()
    private let viewDidLoadRelay = PublishRelay<Void>()
    private let viewWillAppearRelay = PublishRelay<Void>()

    private let customNavigationBar = CustomNavigationBar()

    private var pinterestLayout: PinterestLayout!

    private lazy var collectionView: UICollectionView = {
        pinterestLayout = PinterestLayout()
        pinterestLayout.delegate = self

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: pinterestLayout)
        collectionView.register(CalendarDetailCell.self, forCellWithReuseIdentifier: CalendarDetailCell.identifier)
        collectionView.backgroundColor = .clear
        return collectionView
    }()

    private lazy var dataSource: UICollectionViewDiffableDataSource<Int, Card> = {
        UICollectionViewDiffableDataSource<Int, Card>(collectionView: collectionView) { collectionView, indexPath, card in
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: CalendarDetailCell.identifier,
                for: indexPath
            ) as? CalendarDetailCell else {
                return UICollectionViewCell()
            }
            cell.configure(with: card)
            return cell
        }
    }()

    private let date: Date

    init(date: Date) {
        self.date = date
        self.viewModel = CalendarDetailViewModel(date: date)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        configureUI()
        setupCustomNavigationBar()
        bind()
        viewDidLoadRelay.accept(())
    }

    private func setupCustomNavigationBar() {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 M월 d일"
        customNavigationBar.configure(title: formatter.string(from: date))

        customNavigationBar.onLeftButtonTapped = { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewWillAppearRelay.accept(())
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
            make.top.equalTo(customNavigationBar.snp.bottom)
            make.horizontalEdges.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide)
        }
    }

    private func bind() {
        let input = CalendarDetailViewModel.Input(
            viewDidLoad: viewDidLoadRelay.asObservable(),
            viewWillAppear: viewWillAppearRelay.asObservable(),
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

        output.memos
            .drive(with: self) { owner, cards in
                var snapshot = NSDiffableDataSourceSnapshot<Int, Card>()
                snapshot.appendSections([0])
                snapshot.appendItems(cards)
                owner.dataSource.apply(snapshot, animatingDifferences: false) {
                    owner.pinterestLayout.invalidateLayout()
                    owner.collectionView.reloadData()
                }
            }
            .disposed(by: disposeBag)

        output.navigateToDetail
            .drive(with: self) { owner, photoMemoId in
                let detailVC = PhotoDetailViewController(photoMemoId: photoMemoId)
                detailVC.modalPresentationStyle = .fullScreen
                owner.present(detailVC, animated: true)
            }
            .disposed(by: disposeBag)
    }
}

extension CalendarDetailViewController: PinterestLayoutDelegate {
    func collectionView(_ collectionView: UICollectionView, heightForPhotoAtIndexPath indexPath: IndexPath) -> CGFloat {
        guard let card = dataSource.itemIdentifier(for: indexPath),
              let image = UIImage(data: card.editedImageData) else {
            return 200
        }

        guard image.size.width > 0 else { return 200 }

        let columnWidth = collectionView.bounds.width / 2
        let aspectRatio = image.size.height / image.size.width
        let calculatedHeight = columnWidth * aspectRatio

        return calculatedHeight.isFinite && calculatedHeight > 0 ? calculatedHeight : 200
    }
}
