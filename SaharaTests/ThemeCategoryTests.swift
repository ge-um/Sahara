//
//  ThemeCategoryTests.swift
//  SaharaTests
//
//  Created by 금가경 on 3/13/26.
//

import XCTest
@testable import Sahara

final class ThemeCategoryTests: XCTestCase {

    // MARK: - category(for: [VisionTag]) — Priority Tests

    func test_categoryForVisionTags_emptyArray_returnsOthers() {
        let emptyTags: [VisionTag] = []
        XCTAssertEqual(ThemeCategory.category(for: emptyTags), .others)
    }

    func test_categoryForVisionTags_mixedTags_animalsHasHighestPriority() {
        XCTAssertEqual(ThemeCategory.category(for: [.person, .cat] as [VisionTag]), .animals)
        XCTAssertEqual(ThemeCategory.category(for: [.food, .dog, .building] as [VisionTag]), .animals)
    }

    func test_categoryForVisionTags_mixedTags_peopleBeforeFood() {
        XCTAssertEqual(ThemeCategory.category(for: [.person, .food] as [VisionTag]), .people)
    }

    func test_categoryForVisionTags_mixedTags_foodBeforeNature() {
        XCTAssertEqual(ThemeCategory.category(for: [.food, .nature] as [VisionTag]), .food)
    }

    func test_categoryForVisionTags_mixedTags_natureBeforeBuildings() {
        XCTAssertEqual(ThemeCategory.category(for: [.sky, .building] as [VisionTag]), .nature)
    }
}
