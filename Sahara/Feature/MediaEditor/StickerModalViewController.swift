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
        searchBar.backgroundColor = .clear
        searchBar.setSearchFieldBackgroundImage(UIImage(), for: .normal)

        if let textField = searchBar.value(forKey: "searchField") as? UITextField {
            textField.font = .typography(.label)
            textField.applyGlassCardStyle(cornerRadius: 10)
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

    private let emptyStateLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("media_editor.sticker_load_failed", comment: "")
        label.font = .typography(.body)
        label.textColor = .token(.textSecondary)
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private let retryButton: UIButton = {
        let button = UIButton(type: .system)
        var config = UIButton.Configuration.plain()
        config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20)
        let attributedTitle = AttributedString(
            NSLocalizedString("media_editor.retry", comment: ""),
            attributes: AttributeContainer([
                .font: UIFont.typography(.label),
                .foregroundColor: UIColor.token(.textPrimary)
            ])
        )
        config.attributedTitle = attributedTitle
        button.configuration = config
        button.applyGlassCardStyle(cornerRadius: DesignToken.CornerRadius.button)
        return button
    }()

    private lazy var emptyStateContainer: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [emptyStateLabel, retryButton])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = DesignToken.Spacing.lg
        stack.isHidden = true
        return stack
    }()

    private let viewModel: MediaEditorViewModel
    private let disposeBag = DisposeBag()
    private let viewWillAppearRelay = PublishRelay<Void>()
    private let loadMoreRelay = PublishRelay<Void>()
    private let hasErrorRelay = BehaviorRelay<Bool>(value: false)
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
            stickerButtonTapped: .empty(),
            searchQuery: searchQuery,
            loadMoreTrigger: loadMoreRelay.asObservable(),
            stickerSelected: stickerCollectionView.rx.modelSelected(KlipySticker.self).asObservable(),
            stickerAdded: .empty(),
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

        output.stickers
            .asObservable()
            .filter { !$0.isEmpty }
            .map { _ in false }
            .bind(to: hasErrorRelay)
            .disposed(by: disposeBag)

        output.errorMessage
            .asObservable()
            .filter { !$0.isEmpty }
            .withLatestFrom(output.stickers.asObservable())
            .filter { $0.isEmpty }
            .map { _ in true }
            .bind(to: hasErrorRelay)
            .disposed(by: disposeBag)

        hasErrorRelay
            .asDriver()
            .drive(with: self) { owner, hasError in
                owner.emptyStateContainer.isHidden = !hasError
                owner.stickerCollectionView.isHidden = hasError
            }
            .disposed(by: disposeBag)

        retryButton.rx.tap
            .bind(with: self) { owner, _ in
                owner.searchBar.text = nil
                owner.viewWillAppearRelay.accept(())
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
        view.applyGradient(.tabBar)

        view.addSubview(searchBar)
        view.addSubview(stickerCollectionView)
        view.addSubview(emptyStateContainer)

        searchBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.horizontalEdges.equalToSuperview().inset(12)
            make.height.equalTo(36)
        }

        stickerCollectionView.snp.makeConstraints { make in
            make.top.equalTo(searchBar.snp.bottom).offset(10)
            make.horizontalEdges.bottom.equalToSuperview()
        }

        emptyStateContainer.snp.makeConstraints { make in
            make.center.equalTo(stickerCollectionView)
            make.horizontalEdges.equalToSuperview().inset(40)
        }
    }

    private func configureNavigation() {
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.typography(.body)
        ]
        navigationController?.navigationBar.titleTextAttributes = titleAttributes
        navigationItem.title = NSLocalizedString("media_editor.sticker_modal_title", comment: "")

        let iconSize = CGSize(width: 20, height: 20)
        let xmarkImage = UIImage(named: "xmark").flatMap { original in
            UIGraphicsImageRenderer(size: iconSize).image { _ in
                original.draw(in: CGRect(origin: .zero, size: iconSize))
            }.withRenderingMode(.alwaysTemplate)
        }
        let closeButton = UIBarButtonItem(image: xmarkImage, style: .plain, target: self, action: #selector(closeTapped))
        closeButton.tintColor = .token(.textPrimary)
        navigationItem.leftBarButtonItem = closeButton
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }
}
