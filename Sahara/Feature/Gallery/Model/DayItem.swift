//
//  DayItem.swift
//  Sahara
//
//  Created by 금가경 on 9/29/25.
//

import Foundation

struct DayItem {
    let date: Date?
    let cards: [Card]
    let isCurrentMonth: Bool

    var hasCards: Bool {
        return !cards.isEmpty
    }
}
