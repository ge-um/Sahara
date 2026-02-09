//
//  CardThumbnailCell.swift
//  Sahara
//
//  Created by 금가경 on 10/13/25.
//

import UIKit

final class CardThumbnailCell: BaseCardThumbnailCell {

    private var thumbnailMaxDimension: CGFloat {
        let dimension = max(contentView.bounds.width, contentView.bounds.height)
        return (dimension > 0 ? dimension : 200) * UIScreen.main.scale
    }

    func configure(with item: CardListItemDTO) {
        setImage(item.editedImageData, maxDimension: thumbnailMaxDimension)
        setBlur(isHidden: !item.isLocked)
    }

    func configure(with card: Card) {
        setImage(card.editedImageData, maxDimension: thumbnailMaxDimension)
        setBlur(isHidden: !card.isLocked)
    }
}
