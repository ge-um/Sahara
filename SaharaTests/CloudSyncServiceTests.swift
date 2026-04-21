//
//  CloudSyncServiceTests.swift
//  SaharaTests
//

import XCTest
@testable import Sahara

final class CloudSyncServiceTests: XCTestCase {
    var sut: CloudSyncService!

    override func setUp() {
        super.setUp()
        sut = CloudSyncService(
            realmService: MockRealmService(),
            imageFileService: MockImageFileService()
        )
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - 동시성 안전 + 에코백 방지

    func test_addAndRemoveRemoteModifiedId_threadSafe() {
        let group = DispatchGroup()
        let queue = DispatchQueue(label: "test.concurrent", attributes: .concurrent)
        let iterations = 500

        for i in 0..<iterations {
            let id = "card-\(i)"

            group.enter()
            queue.async {
                self.sut.addRemoteModifiedId(id)
                group.leave()
            }

            group.enter()
            queue.async {
                _ = self.sut.removeRemoteModifiedId(id)
                group.leave()
            }
        }

        let result = group.wait(timeout: .now() + 5)
        XCTAssertEqual(result, .success, "Concurrent access must not deadlock or crash")
    }

    func test_removeRemoteModifiedId_presentId_returnsTrue() {
        sut.addRemoteModifiedId("abc123")

        let result = sut.removeRemoteModifiedId("abc123")

        XCTAssertTrue(result)
    }

    func test_removeRemoteModifiedId_absentId_returnsFalse() {
        let result = sut.removeRemoteModifiedId("never-added")

        XCTAssertFalse(result)
    }
}
