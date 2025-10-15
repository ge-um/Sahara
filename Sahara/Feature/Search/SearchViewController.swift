//
//  SearchViewController.swift
//  Sahara
//
//  Created by 금가경 on 10/8/25.
//

import RealmSwift
import RxCocoa
import RxSwift
import SnapKit
import UIKit

final class SearchViewController: UIViewController {
    private let viewModel = SearchViewModel()
    private let disposeBag = DisposeBag()

    private let customNavigationBar = CustomNavigationBar()


    private let searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = NSLocalizedString("search.placeholder", comment: "")
        searchBar.searchBarStyle = .minimal
        searchBar.backgroundColor = .clear

        if let textField = searchBar.value(forKey: "searchField") as? UITextField {
            textField.font = FontSystem.galmuriMono(size: 14)
        }

        return searchBar
    }()

    private var pinterestLayout: PinterestLayout!

    private lazy var collectionView: UICollectionView = {
        pinterestLayout = PinterestLayout()
        pinterestLayout.delegate = self

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: pinterestLayout)
        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.register(SearchCell.self, forCellWithReuseIdentifier: SearchCell.identifier)
        collectionView.keyboardDismissMode = .onDrag
        return collectionView
    }()

    private let emptyStateLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = FontSystem.galmuriMono(size: 14)
        label.textColor = .black
        label.isHidden = true
        return label
    }()


    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        configureUI()
        setupCustomNavigationBar()
        setupKeyboardDismiss()
        bind()
    }

    private func setupCustomNavigationBar() {
        customNavigationBar.configure(title: NSLocalizedString("tab.search", comment: ""))
        customNavigationBar.hideLeftButton()
    }

    private func setupKeyboardDismiss() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    private func configureUI() {
        view.applyGradientWithDots(.pinkToBlue, dotSize: 5, spacing: 32, dotColor: .white)

        view.addSubview(customNavigationBar)
        view.addSubview(searchBar)
        view.addSubview(collectionView)
        view.addSubview(emptyStateLabel)

        customNavigationBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.horizontalEdges.equalToSuperview()
            make.height.equalTo(54)
        }

        searchBar.snp.makeConstraints { make in
            make.top.equalTo(customNavigationBar.snp.bottom).offset(8)
            make.horizontalEdges.equalToSuperview().inset(20)
            make.height.equalTo(48)
        }

        collectionView.snp.makeConstraints { make in
            make.top.equalTo(searchBar.snp.bottom).offset(16)
            make.horizontalEdges.equalToSuperview().inset(24)
            make.bottom.equalToSuperview().inset(90)
        }

        emptyStateLabel.snp.makeConstraints { make in
            make.centerX.equalTo(collectionView)
            make.top.equalTo(collectionView).offset(100)
            make.horizontalEdges.equalToSuperview().inset(40)
        }
    }

    private func bind() {
        let input = SearchViewModel.Input(
            searchText: searchBar.rx.text.orEmpty.asObservable(),
            itemSelected: collectionView.rx.itemSelected.asObservable()
        )

        let output = viewModel.transform(input: input)

        output.cards
            .drive(collectionView.rx.items(cellIdentifier: SearchCell.identifier, cellType: SearchCell.self)) { _, card, cell in
                cell.configure(with: card)
            }
            .disposed(by: disposeBag)

        Observable.combineLatest(
            output.cards.asObservable(),
            output.emptyState.asObservable()
        )
        .observe(on: MainScheduler.instance)
        .bind(with: self) { owner, data in
            let (cards, state) = data
            let hasResults = !cards.isEmpty

            owner.collectionView.isHidden = !hasResults

            if hasResults {
                owner.emptyStateLabel.isHidden = true
            } else {
                switch state {
                case .initial:
                    owner.emptyStateLabel.isHidden = true
                case .noResults:
                    owner.emptyStateLabel.isHidden = false
                    owner.emptyStateLabel.text = NSLocalizedString("search.no_results", comment: "")
                }
            }
        }
        .disposed(by: disposeBag)

        output.navigateToDetail
            .drive(with: self) { owner, cardId in
                guard let card = owner.viewModel.getCard(by: cardId) else { return }

                if card.isLocked {
                    BiometricAuthManager.shared.authenticate { success, error in
                        if success {
                            let detailVC = CardDetailViewController(cardId: cardId, sourceType: .searchView)
                            owner.navigationController?.pushViewController(detailVC, animated: true)
                        } else {
                            if let error = error as NSError? {
                                if error.domain == "BiometricPermissionError" {
                                    owner.showBiometricPermissionAlert()
                                } else {
                                    owner.showToast(message: error.localizedDescription)
                                }
                            }
                        }
                    }
                } else {
                    let detailVC = CardDetailViewController(cardId: cardId, sourceType: .searchView)
                    owner.navigationController?.pushViewController(detailVC, animated: true)
                }
            }
            .disposed(by: disposeBag)
    }
}

extension SearchViewController: PinterestLayoutDelegate {
    func collectionView(_ collectionView: UICollectionView, heightForPhotoAtIndexPath indexPath: IndexPath) -> CGFloat {
        guard let card = viewModel.getCard(at: indexPath.item),
              let image = UIImage(data: card.editedImageData) else {
            return 180
        }

        let aspectRatio = image.size.height / image.size.width
        let cellWidth = (collectionView.bounds.width - 8) / 2
        return cellWidth * aspectRatio
    }
}

final class SearchCell: UICollectionViewCell {
    static let identifier = "SearchCell"

    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .systemGray6
        return imageView
    }()

    private lazy var blurEffectView: UIVisualEffectView = BlurUtility.createBlurView(cornerRadius: 8)

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureUI() {
        contentView.addSubview(imageView)
        contentView.addSubview(blurEffectView)
        contentView.layer.cornerRadius = 8
        contentView.clipsToBounds = true

        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        blurEffectView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    func configure(with card: Card) {
        if let image = UIImage(data: card.editedImageData) {
            imageView.image = image
        }
        blurEffectView.isHidden = !card.isLocked
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        blurEffectView.isHidden = true
    }
}
