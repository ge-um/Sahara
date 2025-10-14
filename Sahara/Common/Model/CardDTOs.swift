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
}

struct CardDetailDTO {
    let id: ObjectId
    let createdDate: Date
    let editedImageData: Data
    let memo: String?
    let latitude: Double?
    let longitude: Double?
    let isLocked: Bool
    let customFolder: String?

    init(from card: Card) {
        self.id = card.id
        self.createdDate = card.createdDate
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
    let createdDate: Date
    let editedImageData: Data
    let isLocked: Bool

    init(from card: Card) {
        self.id = card.id
        self.createdDate = card.createdDate
        self.editedImageData = card.editedImageData
        self.isLocked = card.isLocked
    }
}
