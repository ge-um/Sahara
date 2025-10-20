//
//  NetworkManagerTests.swift
//  SaharaTests
//
//  Created by 금가경 on 10/21/25.
//

import XCTest
import RxSwift
@testable import Sahara

final class NetworkManagerTests: XCTestCase {
    private var sut: NetworkManager!
    private var disposeBag: DisposeBag!

    override func setUp() {
        super.setUp()
        sut = NetworkManager.shared
        disposeBag = DisposeBag()
    }

    override func tearDown() {
        sut = nil
        disposeBag = nil
        super.tearDown()
    }

    func test_networkManager_shouldBeSharedInstance() {
        let instance1 = NetworkManager.shared
        let instance2 = NetworkManager.shared

        XCTAssertTrue(instance1 === instance2)
    }

    func test_networkError_invalidURL_shouldHaveCorrectDescription() {
        let error = NetworkError.invalidURL

        XCTAssertEqual(error.errorDescription, "잘못된 URL입니다.")
    }

    func test_networkError_notConnectedToInternet_shouldHaveCorrectDescription() {
        let error = NetworkError.notConnectedToInternet

        XCTAssertEqual(
            error.errorDescription,
            "네트워크 연결이 일시적으로 원활하지 않습니다. 데이터 또는 Wi-fi 연결 상태를 확인해 주세요."
        )
    }

    func test_networkError_decodingError_shouldHaveCorrectDescription() {
        let error = NetworkError.decodingError

        XCTAssertEqual(error.errorDescription, "데이터 처리 중 오류가 발생했습니다.")
    }
}
