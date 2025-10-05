//
//  MapViewController.swift
//  Sahara
//
//  Created by 금가경 on 10/1/25.
//

import RealmSwift
import RxCocoa
import RxSwift
import SnapKit
import UIKit

final class MapViewController: UIViewController {
    private let viewModel: MapViewModel
    private let disposeBag = DisposeBag()
    private let viewDidLoadRelay = PublishRelay<Void>()

    private let customNavigationBar = CustomNavigationBar()

    private let closeButton: UIButton = {
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
        collectionView.register(MapMediaCell.self, forCellWithReuseIdentifier: MapMediaCell.identifier)
        return collectionView
    }()

    private let themeCategory: ThemeCategory
    private let customTitle: String?

    init(photoMemos: [Card], themeCategory: ThemeCategory, customTitle: String? = nil) {
        self.viewModel = MapViewModel(photoMemos: photoMemos)
        self.themeCategory = themeCategory
        self.customTitle = customTitle
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
        let title = customTitle ?? themeCategory.localizedName
        customNavigationBar.configure(title: title)
        customNavigationBar.hideLeftButton()

        view.addSubview(closeButton)

        closeButton.snp.makeConstraints { make in
            make.leading.equalTo(customNavigationBar).offset(8)
            make.centerY.equalTo(customNavigationBar)
            make.width.equalTo(44)
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
        let input = MapViewModel.Input(
            viewDidLoad: viewDidLoadRelay.asObservable(),
            itemSelected: collectionView.rx.itemSelected.asObservable(),
            closeButtonTapped: closeButton.rx.tap.asObservable()
        )

        let output = viewModel.transform(input: input)

        output.photoMemos
            .drive(collectionView.rx.items(cellIdentifier: MapMediaCell.identifier, cellType: MapMediaCell.self)) { _, memo, cell in
                cell.configure(with: memo)
            }
            .disposed(by: disposeBag)

        output.navigateToDetail
            .drive(with: self) { owner, photoMemoId in
                let sourceType: EditSourceType = owner.themeCategory == .others ? .locationView : .themeView
                let detailVC = CardDetailViewController(photoMemoId: photoMemoId, sourceType: sourceType)
                owner.navigationController?.pushViewController(detailVC, animated: true)
            }
            .disposed(by: disposeBag)

        output.dismiss
            .drive(with: self) { owner, _ in
                owner.navigationController?.popViewController(animated: true)
            }
            .disposed(by: disposeBag)
    }
}

extension MapViewController: PinterestLayoutDelegate {
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

final class MapMediaCell: UICollectionViewCell {
    static let identifier = "MapMediaCell"

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
