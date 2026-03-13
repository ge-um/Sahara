//
//  CardPostProcessorTests.swift
//  SaharaTests
//
//  Created by 금가경 on 3/13/26.
//

import XCTest
@testable import Sahara

final class CardPostProcessorTests: XCTestCase {
    var sut: CardPostProcessor!

    override func setUp() {
        super.setUp()
        sut = CardPostProcessor()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - mapLabelsToVisionTags

    func test_mapLabelsToVisionTags_duplicatesRemoved() {
        let result = sut.mapLabelsToVisionTags(["cat", "kitten", "feline"])
        XCTAssertEqual(result, [.cat])
    }

    func test_mapLabelsToVisionTags_multipleDistinctTags() {
        let result = sut.mapLabelsToVisionTags(["person", "cat", "outdoor"])
        XCTAssertTrue(result.contains(.person))
        XCTAssertTrue(result.contains(.cat))
        XCTAssertTrue(result.contains(.outdoor))
        XCTAssertEqual(result.count, 3)
    }

    func test_mapLabelsToVisionTags_emptyInput_returnsEmpty() {
        let result = sut.mapLabelsToVisionTags([])
        XCTAssertTrue(result.isEmpty)
    }

    func test_mapLabelsToVisionTags_caseInsensitive() {
        let result = sut.mapLabelsToVisionTags(["PERSON", "Cat"])
        XCTAssertTrue(result.contains(.person))
        XCTAssertTrue(result.contains(.cat))
    }
}
