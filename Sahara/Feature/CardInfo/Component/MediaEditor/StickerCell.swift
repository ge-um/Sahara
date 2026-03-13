//
//  StickerCell.swift
//  Sahara
//
//  Created by 금가경 on 9/26/25.
//

import Kingfisher
import SnapKit
import UIKit

final class StickerCell: UICollectionViewCell, IsIdentifiable {
    private let imageView: AnimatedImageView = {
        let imageView = AnimatedImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
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
        contentView.backgroundColor = .white
        contentView.layer.cornerRadius = 8
        contentView.layer.borderWidth = 1
        contentView.layer.borderColor = UIColor.systemGray5.cgColor

        contentView.addSubview(imageView)

        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(8)
        }
    }

    func configure(with sticker: KlipySticker) {
        guard let url = sticker.resolveImageURL(quality: .lowFirst) else { return }
        imageView.kf.setImage(
            with: url,
            options: [
                .scaleFactor(UIScreen.main.scale),
                .memoryCacheExpiration(.seconds(600)),
                .diskCacheExpiration(.days(7)),
                .cacheOriginalImage,
                .onlyLoadFirstFrame
            ]
        )
    }
}
