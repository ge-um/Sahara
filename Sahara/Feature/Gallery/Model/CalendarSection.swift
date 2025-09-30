//
//  CalendarSection.swift
//  Sahara
//
//  Created by 금가경 on 9/30/25.
//

import RxDataSources

struct CalendarSection {
    var items: [Item]
}

extension CalendarSection: SectionModelType {
    typealias Item = DayItem
    
    init(original: CalendarSection, items: [DayItem]) {
        self = original
        self.items = items
    }
}
