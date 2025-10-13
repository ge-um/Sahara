//
//  StickerModalViewController.swift
//  Sahara
//
//  Created by 금가경 on 10/1/25.
//

import RxCocoa
import RxSwift
import SnapKit
import UIKit

final class StickerModalViewController: UIViewController {
    private let searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = NSLocalizedString("media_editor.sticker_search_placeholder", comment: "")
        searchBar.searchBarStyle = .minimal
        if let textField = searchBar.value(forKey: "searchField") as? UITextField {
            textField.font = FontSystem.galmuriMono(size: 14)
        }
        return searchBar
    }()

    private lazy var stickerCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 80, height: 80)
        layout.minimumLineSpacing = 10
        layout.minimumInteritemSpacing = 10
        layout.sectionInset = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.register(StickerCell.self, forCellWithReuseIdentifier: StickerCell.identifier)
        return collectionView
    }()

    private let viewModel: MediaEditorViewModel
    private let disposeBag = DisposeBag()
    private let viewWillAppearRelay = PublishRelay<Void>()
    private let loadMoreRelay = PublishRelay<Void>()
    var onStickerSelected: ((KlipySticker) -> Void)?

    init(viewModel: MediaEditorViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        configureNavigation()
        bind()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewWillAppearRelay.accept(())
    }

    private func bind() {
        let viewTapGesture = UITapGestureRecognizer()
        viewTapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(viewTapGesture)

        let collectionViewTapGesture = UITapGestureRecognizer()
        collectionViewTapGesture.cancelsTouchesInView = false
        stickerCollectionView.addGestureRecognizer(collectionViewTapGesture)

        Observable.merge(
            viewTapGesture.rx.event.map { _ in () },
            collectionViewTapGesture.rx.event.map { _ in () },
            stickerCollectionView.rx.didScroll.map { _ in () }
        )
        .bind(with: self) { owner, _ in
            owner.view.endEditing(true)
        }
        .disposed(by: disposeBag)

        let searchQuery = searchBar.rx.text
            .orEmpty
            .debounce(.milliseconds(300), scheduler: MainScheduler.instance)
            .distinctUntilChanged()

        let input = MediaEditorViewModel.Input(
            viewWillAppear: viewWillAppearRelay.asObservable(),
            searchQuery: searchQuery,
            loadMoreTrigger: loadMoreRelay.asObservable(),
            stickerSelected: stickerCollectionView.rx.modelSelected(KlipySticker.self).asObservable(),
            filterSelected: .empty(),
            cropApplied: .empty(),
            drawingChanged: .empty(),
            photoSelected: .empty(),
            doneButtonTapped: .empty(),
            cancelButtonTapped: .empty()
        )

        let output = viewModel.transform(input: input)

        output.stickers
            .asObservable()
            .bind(to: stickerCollectionView.rx.items(
                cellIdentifier: StickerCell.identifier,
                cellType: StickerCell.self
            )) { _, sticker, cell in
                cell.configure(with: sticker)
            }
            .disposed(by: disposeBag)

        stickerCollectionView.rx.willDisplayCell
            .withLatestFrom(output.stickers.asObservable()) { cellInfo, stickers in
                (cellInfo.at.item, stickers.count)
            }
            .filter { item, count in
                item >= count - 5
            }
            .map { _ in () }
            .throttle(.seconds(1), scheduler: MainScheduler.instance)
            .bind(to: loadMoreRelay)
            .disposed(by: disposeBag)

        output.selectedSticker
            .drive(with: self) { owner, sticker in
                owner.onStickerSelected?(sticker)
                owner.dismiss(animated: true)
            }
            .disposed(by: disposeBag)
    }

    private func configureUI() {
        view.applyGradient(.whiteToGray)

        navigationController?.view.applyGradient(.whiteToGray)
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.isTranslucent = true

        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: FontSystem.galmuriMono(size: 16)
        ]
        navigationController?.navigationBar.titleTextAttributes = titleAttributes

        view.addSubview(searchBar)
        view.addSubview(stickerCollectionView)

        searchBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.horizontalEdges.equalToSuperview()
        }

        stickerCollectionView.snp.makeConstraints { make in
            make.top.equalTo(searchBar.snp.bottom).offset(10)
            make.horizontalEdges.bottom.equalToSuperview()
        }
    }

    private func configureNavigation() {
        navigationItem.title = NSLocalizedString("media_editor.sticker_modal_title", comment: "")

        let closeButton = UIBarButtonItem(
            image: UIImage(systemName: "xmark"),
            style: .plain,
            target: nil,
            action: nil
        )
        closeButton.tintColor = .label
        navigationItem.leftBarButtonItem = closeButton

        closeButton.rx.tap
            .bind(with: self) { owner, _ in
                owner.dismiss(animated: true)
            }
            .disposed(by: disposeBag)
    }
}
