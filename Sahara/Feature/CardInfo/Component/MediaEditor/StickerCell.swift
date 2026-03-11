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
        var urlString: String?

        if let sm = sticker.file.sm {
            urlString = sm.gif?.url ?? sm.webp?.url
        } else if let xs = sticker.file.xs {
            urlString = xs.gif?.url ?? xs.webp?.url
        } else if let md = sticker.file.md {
            urlString = md.gif?.url ?? md.webp?.url
        } else if let hd = sticker.file.hd {
            urlString = hd.gif?.url ?? hd.webp?.url
        }

        if let urlString = urlString, let url = URL(string: urlString) {
            let options: KingfisherOptionsInfo = [
                .scaleFactor(window?.screen.scale ?? 2.0),
                .memoryCacheExpiration(.seconds(600)),
                .diskCacheExpiration(.days(7)),
                .cacheOriginalImage,
                .onlyLoadFirstFrame
            ]
            imageView.kf.setImage(with: url, options: options)
        }
    }
}
