//
//  OnThisDaySelectorTests.swift
//  SaharaTests
//
//  Created by 금가경 on 3/11/26.
//

import XCTest
@testable import Sahara

final class OnThisDaySelectorTests: XCTestCase {

    private func makeEntry(
        cardId: String = UUID().uuidString,
        date: Date,
        memo: String? = nil
    ) -> WidgetCardEntry {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month, .day], from: date)
        return WidgetCardEntry(
            cardId: cardId,
            date: date,
            memo: memo,
            monthDay: .init(month: components.month!, day: components.day!),
            thumbnailFileName: "\(cardId)_widget.jpg"
        )
    }

    private func date(year: Int, month: Int, day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        return Calendar.current.date(from: components)!
    }

    func test_onThisDay_prefersPreviousYearSameDate() {
        let today = date(year: 2026, month: 3, day: 11)
        let lastYear = makeEntry(cardId: "old", date: date(year: 2025, month: 3, day: 11))
        let otherDay = makeEntry(cardId: "other", date: date(year: 2025, month: 5, day: 20))
        let entries = [lastYear, otherDay]

        for _ in 0..<20 {
            guard let result = OnThisDaySelector.select(from: entries, today: today) else {
                XCTFail("Expected a selection")
                return
            }
            XCTAssertEqual(result.entry.cardId, "old")
            XCTAssertTrue(result.isOnThisDay)
        }
    }

    func test_onThisDay_leapYearFeb29() {
        let today = date(year: 2028, month: 2, day: 29)
        let leapEntry = makeEntry(cardId: "leap", date: date(year: 2024, month: 2, day: 29))
        let otherEntry = makeEntry(cardId: "other", date: date(year: 2025, month: 6, day: 15))

        guard let result = OnThisDaySelector.select(from: [leapEntry, otherEntry], today: today) else {
            XCTFail("Expected a selection")
            return
        }
        XCTAssertEqual(result.entry.cardId, "leap")
        XCTAssertTrue(result.isOnThisDay)
    }

    func test_onThisDay_excludesTodayCards() {
        let today = date(year: 2026, month: 3, day: 11)
        let todayEntry = makeEntry(cardId: "today", date: today)
        let otherEntry = makeEntry(cardId: "other", date: date(year: 2026, month: 1, day: 5))

        for _ in 0..<20 {
            guard let result = OnThisDaySelector.select(from: [todayEntry, otherEntry], today: today) else {
                XCTFail("Expected a selection")
                return
            }
            XCTAssertFalse(result.isOnThisDay)
        }
    }

    func test_onThisDay_excludesTodayCards_multipleSameDayEntries() {
        let today = date(year: 2026, month: 3, day: 11)
        let todayEntry1 = makeEntry(cardId: "today1", date: today)
        let todayEntry2 = makeEntry(cardId: "today2", date: today)

        guard let result = OnThisDaySelector.select(from: [todayEntry1, todayEntry2], today: today) else {
            XCTFail("Expected a selection")
            return
        }
        XCTAssertFalse(result.isOnThisDay)
    }

    func test_fallbackToRandom_whenNoOnThisDay() {
        let today = date(year: 2026, month: 3, day: 11)
        let entry = makeEntry(cardId: "only", date: date(year: 2025, month: 7, day: 20))

        guard let result = OnThisDaySelector.select(from: [entry], today: today) else {
            XCTFail("Expected a selection")
            return
        }
        XCTAssertEqual(result.entry.cardId, "only")
        XCTAssertFalse(result.isOnThisDay)
    }

    func test_emptyEntries_returnsNil() {
        let result = OnThisDaySelector.select(from: [])
        XCTAssertNil(result)
    }
}
