//
//  Date+RelativeFormat.swift
//  Sahara
//
//  Created by 금가경 on 10/12/25.
//

import Foundation

extension Date {
    func relativeOrAbsoluteString() -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.day], from: self, to: now)

        guard let days = components.day else {
            return absoluteDateString()
        }

        if days == 0 {
            return NSLocalizedString("date.today", comment: "")
        } else if days > 0 && days <= 7 {
            return String(format: NSLocalizedString("date.days_ago", comment: ""), days)
        } else {
            return absoluteDateString()
        }
    }

    private func absoluteDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yy.MM.dd"
        return formatter.string(from: self)
    }
}
