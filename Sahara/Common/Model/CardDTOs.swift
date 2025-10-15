//
//  CardDTOs.swift
//  Sahara
//
//  Created by 금가경 on 10/15/25.
//

import Foundation
import RealmSwift

struct CardListItemDTO {
    let id: ObjectId
    let editedImageData: Data
    let isLocked: Bool

    init(from card: Card) {
        self.id = card.id
        self.editedImageData = card.editedImageData
        self.isLocked = card.isLocked
    }

    init(from dto: CardCalendarItemDTO) {
        self.id = dto.id
        self.editedImageData = dto.editedImageData
        self.isLocked = dto.isLocked
    }
}

struct CardDetailDTO {
    let id: ObjectId
    let date: Date
    let editedImageData: Data
    let memo: String?
    let latitude: Double?
    let longitude: Double?
    let isLocked: Bool
    let customFolder: String?

    init(from card: Card) {
        self.id = card.id
        self.date = card.date
        self.editedImageData = card.editedImageData
        self.memo = card.memo
        self.latitude = card.latitude
        self.longitude = card.longitude
        self.isLocked = card.isLocked
        self.customFolder = card.customFolder
    }
}

struct CardCalendarItemDTO {
    let id: ObjectId
    let date: Date
    let editedImageData: Data
    let isLocked: Bool

    init(from card: Card) {
        self.id = card.id
        self.date = card.date
        self.editedImageData = card.editedImageData
        self.isLocked = card.isLocked
    }
}
