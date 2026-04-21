//
//  WidgetCardEntry.swift
//  Sahara
//
//  Created by 금가경 on 3/11/26.
//

import Foundation

struct WidgetCardEntry: Codable {
    let cardId: String
    let date: Date
    let memo: String?
    let monthDay: MonthDay
    let thumbnailFileName: String?

    struct MonthDay: Codable, Equatable {
        let month: Int
        let day: Int
    }
}
