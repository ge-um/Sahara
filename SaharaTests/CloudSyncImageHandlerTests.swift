//
//  CloudSyncImageHandlerTests.swift
//  SaharaTests
//

import CloudKit
import RealmSwift
import XCTest
@testable import Sahara

final class CloudSyncImageHandlerTests: XCTestCase {
    var mockImageFileService: MockImageFileService!
    var tempFileURL: URL!

    override func setUp() {
        super.setUp()
        mockImageFileService = MockImageFileService()

        // CKAsset requires a real file on disk — use minimal stub data
        tempFileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("test-asset-\(UUID().uuidString).dat")
        try? Data([0xFF, 0xD8]).write(to: tempFileURL)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempFileURL)
        mockImageFileService = nil
        tempFileURL = nil
        super.tearDown()
    }

    // MARK: - 에러 전파 방지

    func test_saveAssetToDisk_saveFailure_returnsNil() {
        mockImageFileService.shouldFailSave = true
        let asset = CKAsset(fileURL: tempFileURL)
        let cardId = ObjectId.generate()

        let result = CloudSyncImageHandler.saveAssetToDisk(
            asset,
            cardId: cardId,
            format: "jpeg",
            imageFileService: mockImageFileService
        )

        XCTAssertNil(result)
        XCTAssertTrue(mockImageFileService.saveCalled)
    }

    func test_saveAssetToDisk_nilFormat_defaultsToJpeg() {
        let asset = CKAsset(fileURL: tempFileURL)
        let cardId = ObjectId.generate()

        let result = CloudSyncImageHandler.saveAssetToDisk(
            asset,
            cardId: cardId,
            format: nil,
            imageFileService: mockImageFileService
        )

        XCTAssertNotNil(result)
        XCTAssertEqual(mockImageFileService.lastSavedFormat, "jpeg")
    }
}
