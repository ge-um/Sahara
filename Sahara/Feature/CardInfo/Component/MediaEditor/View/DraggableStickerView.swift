//
//  DraggableStickerView.swift
//  Sahara
//
//  Created by 금가경 on 9/26/25.
//

import Kingfisher
import UIKit

final class DraggableStickerView: BaseGestureView {
    private let imageView: AnimatedImageView = {
        let imageView = AnimatedImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    var stickerURL: URL?

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
            urlString = hd.gif?.url ?? hd.webp?.url
        } else if let md = sticker.file.md {
            urlString = md.gif?.url ?? md.webp?.url
        } else if let sm = sticker.file.sm {
            urlString = sm.gif?.url ?? sm.webp?.url
        } else if let xs = sticker.file.xs {
            urlString = xs.gif?.url ?? xs.webp?.url
        }

        if let urlString = urlString, let url = URL(string: urlString) {
            self.stickerURL = url
            let options: KingfisherOptionsInfo = [
                .scaleFactor(UIScreen.main.scale),
                .memoryCacheExpiration(.seconds(600)),
                .diskCacheExpiration(.days(7)),
                .cacheOriginalImage
            ]
            imageView.kf.setImage(with: url, options: options)
        }
    }
}