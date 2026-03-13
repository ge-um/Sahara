//
//  APIRouterTests.swift
//  SaharaTests
//
//  Created by 금가경 on 10/21/25.
//

import XCTest
@testable import Sahara

final class APIRouterTests: XCTestCase {

    func test_trendingStickers_shouldGenerateCorrectURL() {
        let router = APIRouter.trendingStickers(
            page: 1,
            perPage: 20,
            customerId: "test-customer",
            locale: "en"
        )

        let url = router.endPoint

        XCTAssertNotNil(url)
        XCTAssertTrue(url?.absoluteString.contains("stickers/trending") ?? false)
        XCTAssertTrue(url?.absoluteString.contains("page=1") ?? false)
        XCTAssertTrue(url?.absoluteString.contains("per_page=20") ?? false)
        XCTAssertTrue(url?.absoluteString.contains("customer_id=test-customer") ?? false)
        XCTAssertTrue(url?.absoluteString.contains("locale=en") ?? false)
    }

    func test_searchStickers_shouldGenerateCorrectURL() {
        let router = APIRouter.searchStickers(
            query: "cat",
            page: 2,
            perPage: 10,
            customerId: "test-customer",
            locale: "ko"
        )

        let url = router.endPoint

        XCTAssertNotNil(url)
        XCTAssertTrue(url?.absoluteString.contains("stickers/search") ?? false)
        XCTAssertTrue(url?.absoluteString.contains("q=cat") ?? false)
        XCTAssertTrue(url?.absoluteString.contains("page=2") ?? false)
        XCTAssertTrue(url?.absoluteString.contains("per_page=10") ?? false)
        XCTAssertTrue(url?.absoluteString.contains("customer_id=test-customer") ?? false)
        XCTAssertTrue(url?.absoluteString.contains("locale=ko") ?? false)
    }

    func test_searchStickers_withSpecialCharacters_shouldEncodeQuery() {
        let router = APIRouter.searchStickers(
            query: "hello world",
            page: 1,
            perPage: 20,
            customerId: "test",
            locale: "en"
        )

        let url = router.endPoint

        XCTAssertNotNil(url)
        XCTAssertTrue(url?.absoluteString.contains("hello%20world") ?? false)
    }
}
