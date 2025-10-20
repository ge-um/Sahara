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

    func test_trendingStickers_shouldHaveGetMethod() {
        let router = APIRouter.trendingStickers(
            page: 1,
            perPage: 20,
            customerId: "test",
            locale: "en"
        )

        XCTAssertEqual(router.method.rawValue, "GET")
    }

    func test_searchStickers_shouldHaveGetMethod() {
        let router = APIRouter.searchStickers(
            query: "test",
            page: 1,
            perPage: 20,
            customerId: "test",
            locale: "en"
        )

        XCTAssertEqual(router.method.rawValue, "GET")
    }

    func test_trendingStickers_shouldHaveCorrectPath() {
        let router = APIRouter.trendingStickers(
            page: 1,
            perPage: 20,
            customerId: "test",
            locale: "en"
        )

        XCTAssertTrue(router.path.contains("stickers/trending"))
        XCTAssertTrue(router.path.contains(router.appKey))
    }

    func test_searchStickers_shouldHaveCorrectPath() {
        let router = APIRouter.searchStickers(
            query: "test",
            page: 1,
            perPage: 20,
            customerId: "test",
            locale: "en"
        )

        XCTAssertTrue(router.path.contains("stickers/search"))
        XCTAssertTrue(router.path.contains(router.appKey))
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

    func test_trendingStickers_shouldHaveAllParameters() {
        let router = APIRouter.trendingStickers(
            page: 5,
            perPage: 50,
            customerId: "custom-123",
            locale: "ja"
        )

        guard let parameters = router.parameters else {
            XCTFail("Parameters should not be nil")
            return
        }

        XCTAssertEqual(parameters["page"], "5")
        XCTAssertEqual(parameters["per_page"], "50")
        XCTAssertEqual(parameters["customer_id"], "custom-123")
        XCTAssertEqual(parameters["locale"], "ja")
    }

    func test_searchStickers_shouldHaveAllParameters() {
        let router = APIRouter.searchStickers(
            query: "dog",
            page: 3,
            perPage: 15,
            customerId: "custom-456",
            locale: "fr"
        )

        guard let parameters = router.parameters else {
            XCTFail("Parameters should not be nil")
            return
        }

        XCTAssertEqual(parameters["q"], "dog")
        XCTAssertEqual(parameters["page"], "3")
        XCTAssertEqual(parameters["per_page"], "15")
        XCTAssertEqual(parameters["customer_id"], "custom-456")
        XCTAssertEqual(parameters["locale"], "fr")
    }
}
