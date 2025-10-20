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
    private let imageView: UIImageView = {
        let imageView = UIImageView()
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
        // 작은 사이즈(sm)의 이미지를 우선적으로 사용 (썸네일용)
        var urlString: String?

        if let sm = sticker.file.sm {
            urlString = sm.webp?.url ?? sm.gif?.url
        } else if let xs = sticker.file.xs {
            urlString = xs.webp?.url ?? xs.gif?.url
        } else if let md = sticker.file.md {
            urlString = md.webp?.url ?? md.gif?.url
        } else if let hd = sticker.file.hd {
            urlString = hd.webp?.url ?? hd.gif?.url
        }

        if let urlString = urlString, let url = URL(string: urlString) {
            let options: KingfisherOptionsInfo = [
                .processor(DownsamplingImageProcessor(size: CGSize(width: 200, height: 200))),
                .scaleFactor(UIScreen.main.scale),
                .memoryCacheExpiration(.seconds(600)),
                .diskCacheExpiration(.days(7))
            ]
            imageView.kf.setImage(with: url, options: options)
        }
    }
}
