//
//  MapPhotoGalleryViewController.swift
//  Sahara
//
//  Created by Claude on 10/1/25.
//

import SnapKit
import UIKit

final class MapPhotoGalleryViewController: UIViewController {
    private let photoMemos: [PhotoMemo]

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
        collectionView.dataSource = self
        collectionView.delegate = self
        return collectionView
    }()

    init(photoMemos: [PhotoMemo]) {
        self.photoMemos = photoMemos
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
    }

    private func configureUI() {
        view.backgroundColor = .systemBackground
        title = "\(photoMemos.count)개의 사진"

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(closeButtonTapped)
        )

        view.addSubview(collectionView)

        collectionView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
    }

    @objc private func closeButtonTapped() {
        dismiss(animated: true)
    }
}

extension MapPhotoGalleryViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photoMemos.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: MapPhotoCell.identifier,
            for: indexPath
        ) as? MapPhotoCell else {
            return UICollectionViewCell()
        }

        cell.configure(with: photoMemos[indexPath.item])
        return cell
    }
}

extension MapPhotoGalleryViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let photoMemo = photoMemos[indexPath.item]
        let detailVC = PhotoDetailViewController(photoMemoId: photoMemo.id)
        detailVC.modalPresentationStyle = .fullScreen
        present(detailVC, animated: true)
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

    func configure(with photoMemo: PhotoMemo) {
        if let image = UIImage(data: photoMemo.imageData) {
            imageView.image = image
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
    }
}