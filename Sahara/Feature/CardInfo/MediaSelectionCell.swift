//
//  MediaSelectionCell.swift
//  Sahara
//
//  Created by 금가경 on 10/14/25.
//

import Photos
import UIKit

final class MediaSelectionCell: UICollectionViewCell {
    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    func configure(with asset: PHAsset, imageManager: PHCachingImageManager) {
        let size = CGSize(width: 200, height: 200)
        imageManager.requestImage(
            for: asset,
            targetSize: size,
            contentMode: .aspectFill,
            options: nil
        ) { [weak self] image, _ in
            self?.imageView.image = image
        }
    }
}
