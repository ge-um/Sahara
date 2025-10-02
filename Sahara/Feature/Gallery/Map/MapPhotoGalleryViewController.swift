//
//  MapPhotoGalleryViewController.swift
//  Sahara
//
//  Created by 금가경 on 10/1/25.
//

import RxCocoa
import RxSwift
import SnapKit
import UIKit

final class MapPhotoGalleryViewController: UIViewController {
    private let viewModel: MapPhotoGalleryViewModel
    private let disposeBag = DisposeBag()
    private let viewDidLoadRelay = PublishRelay<Void>()

    private let closeButton = UIBarButtonItem(barButtonSystemItem: .close, target: nil, action: nil)

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let spacing: CGFloat = 2
        let itemsPerRow: CGFloat = 3
        let totalSpacing = spacing * (itemsPerRow + 1)
        let itemWidth = (UIScreen.main.bounds.width - totalSpacing) / itemsPerRow

        layout.itemSize = CGSize(width: itemWidth, height: itemWidth)
        layout.minimumLineSpacing = spacing
        layout.minimumInteritemSpacing = spacing
        layout.sectionInset = UIEdgeInsets(top: spacing, left: spacing, bottom: spacing, right: spacing)

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .systemBackground
        collectionView.register(MapPhotoCell.self, forCellWithReuseIdentifier: MapPhotoCell.identifier)
        return collectionView
    }()

    init(photoMemos: [Card]) {
        self.viewModel = MapPhotoGalleryViewModel(photoMemos: photoMemos)
        super.init(nibName: nil, bundle: nil)
        title = String(format: NSLocalizedString("common.photo_count", comment: ""), photoMemos.count)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        bind()
        viewDidLoadRelay.accept(())
    }

    private func configureUI() {
        view.backgroundColor = .systemBackground
        navigationItem.leftBarButtonItem = closeButton

        view.addSubview(collectionView)

        collectionView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
    }

    private func bind() {
        let input = MapPhotoGalleryViewModel.Input(
            viewDidLoad: viewDidLoadRelay.asObservable(),
            itemSelected: collectionView.rx.itemSelected.asObservable(),
            closeButtonTapped: closeButton.rx.tap.asObservable()
        )

        let output = viewModel.transform(input: input)

        output.photoMemos
            .drive(collectionView.rx.items(cellIdentifier: MapPhotoCell.identifier, cellType: MapPhotoCell.self)) { _, memo, cell in
                cell.configure(with: memo)
            }
            .disposed(by: disposeBag)

        output.navigateToDetail
            .drive(with: self) { owner, photoMemoId in
                let detailVC = PhotoDetailViewController(photoMemoId: photoMemoId)
                detailVC.modalPresentationStyle = .fullScreen
                owner.present(detailVC, animated: true)
            }
            .disposed(by: disposeBag)

        output.dismiss
            .drive(with: self) { owner, _ in
                owner.dismiss(animated: true)
            }
            .disposed(by: disposeBag)
    }
}

final class MapPhotoCell: UICollectionViewCell {
    static let identifier = "MapPhotoCell"

    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .systemGray6
        return imageView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureUI() {
        contentView.addSubview(imageView)
        contentView.layer.cornerRadius = 8
        contentView.clipsToBounds = true

        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    func configure(with photoMemo: Card) {
        if let image = UIImage(data: photoMemo.editedImageData) {
            imageView.image = image
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
    }
}
