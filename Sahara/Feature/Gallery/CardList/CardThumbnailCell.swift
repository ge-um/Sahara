//
//  CardThumbnailCell.swift
//  Sahara
//
//  Created by 금가경 on 10/13/25.
//

import UIKit

final class CardThumbnailCell: BaseCardThumbnailCell {

    func configure(with item: CardListItemDTO) {
        ThumbnailCache.shared.loadThumbnail(for: item.id, size: .medium) { [weak self] image in
            self?.imageView.image = image
        }
        setBlur(isHidden: !item.isLocked)
    }

    func configure(with card: Card) {
        ThumbnailCache.shared.loadThumbnail(for: card.id, size: .medium) { [weak self] image in
            self?.imageView.image = image
        }
        setBlur(isHidden: !card.isLocked)
    }
}
