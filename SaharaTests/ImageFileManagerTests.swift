//
//  ImageFileManagerTests.swift
//  SaharaTests
//
//  Created by 금가경 on 3/6/26.
//

import XCTest
import RealmSwift
@testable import Sahara

final class ImageFileManagerTests: XCTestCase {
    var sut: ImageFileManager!
    var testDirectory: URL!

    override func setUp() {
        super.setUp()
        testDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ImageFileManagerTests-\(UUID().uuidString)")
        sut = ImageFileManager(baseDirectory: testDirectory)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: testDirectory)
        sut = nil
        testDirectory = nil
        super.tearDown()
    }

    // MARK: - Save

    func test_saveImageFile_writesFileToDisk() throws {
        let cardId = ObjectId.generate()
        let data = Data([0xFF, 0xD8, 0xFF, 0xE0])

        let fileName = try sut.saveImageFile(data: data, cardId: cardId, format: "jpeg")

        let fileURL = testDirectory.appendingPathComponent(fileName)
        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))
    }

    func test_saveImageFile_returnsCorrectFileName() throws {
        let cardId = ObjectId.generate()
        let data = Data([0x01])

        let fileName = try sut.saveImageFile(data: data, cardId: cardId, format: "heic")

        XCTAssertEqual(fileName, "\(cardId.stringValue).heic")
    }

    func test_saveImageFile_overwritesExistingFile() throws {
        let cardId = ObjectId.generate()
        let originalData = Data([0x01, 0x02])
        let newData = Data([0x03, 0x04, 0x05])

        _ = try sut.saveImageFile(data: originalData, cardId: cardId, format: "jpeg")
        _ = try sut.saveImageFile(data: newData, cardId: cardId, format: "jpeg")

        let loaded = sut.loadImageFile(at: "\(cardId.stringValue).jpeg")
        XCTAssertEqual(loaded, newData)
    }

    // MARK: - Load

    func test_loadImageFile_returnsSavedData() throws {
        let cardId = ObjectId.generate()
        let data = Data([0x89, 0x50, 0x4E, 0x47])

        let fileName = try sut.saveImageFile(data: data, cardId: cardId, format: "png")
        let loaded = sut.loadImageFile(at: fileName)

        XCTAssertEqual(loaded, data)
    }

    func test_loadImageFile_nonexistentFile_returnsNil() {
        let result = sut.loadImageFile(at: "nonexistent.jpeg")

        XCTAssertNil(result)
    }

    // MARK: - Delete

    func test_deleteImageFile_removesFile() throws {
        let cardId = ObjectId.generate()
        let data = Data([0x01])

        let fileName = try sut.saveImageFile(data: data, cardId: cardId, format: "jpeg")
        sut.deleteImageFile(at: fileName)

        let loaded = sut.loadImageFile(at: fileName)
        XCTAssertNil(loaded)
    }

    func test_deleteImageFile_nonexistentFile_doesNotCrash() {
        sut.deleteImageFile(at: "nonexistent.jpeg")
        // No crash = pass
    }

    // MARK: - Init

    func test_init_createsBaseDirectoryIfNotExists() {
        XCTAssertTrue(FileManager.default.fileExists(atPath: testDirectory.path))
    }
}
