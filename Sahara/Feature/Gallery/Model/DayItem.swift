//
//  DayItem.swift
//  Sahara
//
//  Created by 금가경 on 9/29/25.
//

import Foundation

struct DayItem {
    let date: Date?
    let photoMemos: [PhotoMemo]

    var hasPhotos: Bool {
        return !photoMemos.isEmpty
    }
}
