//
//  DayItem.swift
//  Sahara
//
//  Created by 금가경 on 9/29/25.
//

import Foundation
import RealmSwift

struct DayItem {
    let date: Date?
    let cards: [CardCalendarItemDTO]
    let isCurrentMonth: Bool

    var hasCards: Bool {
        return !cards.isEmpty
    }
}
