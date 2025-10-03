//
//  MapPhotoGalleryViewController.swift
//  Sahara
//
//  Created by 금가경 on 10/1/25.
//

import RealmSwift
import RxCocoa
import RxSwift
import SnapKit
import UIKit

final class MapPhotoGalleryViewController: UIViewController {
    private let viewModel: MapPhotoGalleryViewModel
    private let disposeBag = DisposeBag()
    private let viewDidLoadRelay = PublishRelay<Void>()

    private let customNavigationBar = CustomNavigationBar()

    private let closeButton: UIButton = {
        let button = UIButton()
        var config = UIButton.Configuration.filled()
        config.image = UIImage(named: "xmark")
        config.baseBackgroundColor = .white
        config.baseForegroundColor = .black
        config.cornerStyle = .medium
        button.configuration = config
        return button
    }()

    private var pinterestLayout: PinterestLayout!

    private lazy var collectionView: UICollectionView = {
        pinterestLayout = PinterestLayout()
        pinterestLayout.delegate = self

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: pinterestLayout)
        collectionView.backgroundColor = .clear
        collectionView.register(MapPhotoCell.self, forCellWithReuseIdentifier: MapPhotoCell.identifier)
        return collectionView
    }()

    private let themeCategory: ThemeCategory

    init(photoMemos: [Card], themeCategory: ThemeCategory) {
        self.viewModel = MapPhotoGalleryViewModel(photoMemos: photoMemos)
        self.themeCategory = themeCategory
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
        customNavigationBar.configure(title: themeCategory.localizedName)

        view.addSubview(closeButton)

        closeButton.snp.makeConstraints { make in
            make.leading.equalTo(customNavigationBar).offset(16)
            make.centerY.equalTo(customNavigationBar)
            make.width.equalTo(48)
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
                let detailVC = CardDetailViewController(photoMemoId: photoMemoId)
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

extension MapPhotoGalleryViewController: PinterestLayoutDelegate {
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
