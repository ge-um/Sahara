//
//  OnThisDaySelector.swift
//  Sahara
//
//  Created by 금가경 on 3/11/26.
//

import Foundation

struct SelectedCard {
    let entry: WidgetCardEntry
    let isOnThisDay: Bool
}

enum OnThisDaySelector {
    static func select(from entries: [WidgetCardEntry], today: Date = Date()) -> SelectedCard? {
        guard !entries.isEmpty else { return nil }

        let calendar = Calendar.current
        let todayComponents = calendar.dateComponents([.year, .month, .day], from: today)
        guard let todayMonth = todayComponents.month,
              let todayDay = todayComponents.day,
              let todayYear = todayComponents.year else {
            return entries.randomElement().map { SelectedCard(entry: $0, isOnThisDay: false) }
        }

        let onThisDayEntries = entries.filter { entry in
            entry.monthDay.month == todayMonth
            && entry.monthDay.day == todayDay
            && calendar.component(.year, from: entry.date) != todayYear
        }

        if let selected = onThisDayEntries.randomElement() {
            return SelectedCard(entry: selected, isOnThisDay: true)
        }

        guard let selected = entries.randomElement() else { return nil }
        return SelectedCard(entry: selected, isOnThisDay: false)
    }
}
