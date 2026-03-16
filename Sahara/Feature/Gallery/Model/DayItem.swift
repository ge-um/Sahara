//
//  DayItem.swift
//  Sahara
//
//  Created by 금가경 on 9/29/25.
//

import Foundation
import RealmSwift

struct DayItem: Hashable {
    let date: Date?
    let cards: [CardCalendarItemDTO]
    let isCurrentMonth: Bool

    var hasCards: Bool {
        return !cards.isEmpty
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(date)
        hasher.combine(isCurrentMonth)
    }

    static func == (lhs: DayItem, rhs: DayItem) -> Bool {
        lhs.date == rhs.date && lhs.isCurrentMonth == rhs.isCurrentMonth
    }
}
