//
//  CardThumbnailCell.swift
//  Sahara
//
//  Created by 금가경 on 10/13/25.
//

import UIKit

final class CardThumbnailCell: BaseCardThumbnailCell {

    private var thumbnailPixelSize: CGFloat {
        ThumbnailCache.maxPixelSize(for: bounds.size, scale: traitCollection.displayScale)
    }

    func configure(with item: CardListItemDTO) {
        ThumbnailCache.shared.loadThumbnail(for: item.id, maxPixelSize: thumbnailPixelSize) { [weak self] image in
            self?.imageView.image = image
        }
        setBlur(isHidden: !item.isLocked)
    }

    func configure(with item: SearchCardDTO) {
        ThumbnailCache.shared.loadThumbnail(for: item.id, maxPixelSize: thumbnailPixelSize) { [weak self] image in
            self?.imageView.image = image
        }
        setBlur(isHidden: !item.isLocked)
    }
}
