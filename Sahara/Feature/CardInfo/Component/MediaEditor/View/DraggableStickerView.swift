//
//  DraggableStickerView.swift
//  Sahara
//
//  Created by 금가경 on 9/26/25.
//

import Kingfisher
import UIKit

final class DraggableStickerView: BaseGestureView {
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
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
        addSubview(imageView)
        imageView.frame = bounds
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }

    func configure(with sticker: KlipySticker) {
        var urlString: String?

        if let hd = sticker.file.hd {
            urlString = hd.webp?.url ?? hd.gif?.url
        } else if let md = sticker.file.md {
            urlString = md.webp?.url ?? md.gif?.url
        } else if let sm = sticker.file.sm {
            urlString = sm.webp?.url ?? sm.gif?.url
        } else if let xs = sticker.file.xs {
            urlString = xs.webp?.url ?? xs.gif?.url
        }

        if let urlString = urlString, let url = URL(string: urlString) {
            let options: KingfisherOptionsInfo = [
                .processor(DownsamplingImageProcessor(size: bounds.size)),
                .scaleFactor(UIScreen.main.scale),
                .memoryCacheExpiration(.seconds(600)),
                .diskCacheExpiration(.days(7))
            ]
            imageView.kf.setImage(with: url, options: options)
        }
    }
}