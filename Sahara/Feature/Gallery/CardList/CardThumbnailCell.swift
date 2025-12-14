//
//  CardThumbnailCell.swift
//  Sahara
//
//  Created by 금가경 on 10/13/25.
//

import UIKit

final class CardThumbnailCell: BaseCardThumbnailCell {

    func configure(with item: CardListItemDTO) {
        setImage(item.editedImageData)
        setBlur(isHidden: !item.isLocked)
    }

    func configure(with card: Card) {
        setImage(card.editedImageData)
        setBlur(isHidden: !card.isLocked)
    }
}
