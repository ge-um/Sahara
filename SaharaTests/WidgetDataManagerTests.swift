//
//  WidgetDataManagerTests.swift
//  SaharaTests
//
//  Created by 금가경 on 3/11/26.
//

import XCTest
import RealmSwift
@testable import Sahara

final class WidgetDataManagerTests: XCTestCase {
    var testDirectory: URL!
    var thumbnailsDirectory: URL!
    var cardStoreURL: URL!
    var mockRealmManager: MockRealmManager!

    override func setUp() {
        super.setUp()
        testDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("WidgetDataManagerTests-\(UUID().uuidString)")
        thumbnailsDirectory = testDirectory.appendingPathComponent("thumbnails")
        cardStoreURL = testDirectory.appendingPathComponent("WidgetCardStore.json")
        try? FileManager.default.createDirectory(at: testDirectory, withIntermediateDirectories: true)
        mockRealmManager = MockRealmManager()
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: testDirectory)
        testDirectory = nil
        thumbnailsDirectory = nil
        cardStoreURL = nil
        mockRealmManager = nil
        super.tearDown()
    }

    private func makeSut() -> WidgetDataManager {
        WidgetDataManager(
            realmManager: mockRealmManager,
            widgetDirectory: testDirectory,
            thumbnailsDirectory: thumbnailsDirectory,
            cardStoreURL: cardStoreURL
        )
    }

    private func makeCard(date: Date = Date(), isLocked: Bool = false, withImage: Bool = true) -> Card {
        Card(
            date: date,
            createdDate: Date(),
            editedImageData: withImage ? createTestImageData() : nil,
            memo: "Test memo",
            isLocked: isLocked
        )
    }

    private func loadEntries() -> [WidgetCardEntry] {
        guard let data = try? Data(contentsOf: cardStoreURL) else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([WidgetCardEntry].self, from: data)) ?? []
    }

    private func createTestImageData() -> Data {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 100, height: 100))
        return renderer.jpegData(withCompressionQuality: 0.5) { context in
            UIColor.red.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 100, height: 100))
        }
    }

    func test_refreshWidgetData_writesValidJSON() {
        let card = makeCard()
        mockRealmManager.mockCards = [card]
        let sut = makeSut()
        let expectation = XCTestExpectation(description: "Widget data refreshed")

        sut.refreshWidgetData {
            let exists = FileManager.default.fileExists(atPath: self.cardStoreURL.path)
            XCTAssertTrue(exists, "JSON file should be created")

            let entries = self.loadEntries()
            XCTAssertEqual(entries.count, 1)
            XCTAssertEqual(entries.first?.cardId, card.id.stringValue)

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 10)
    }

    func test_refreshWidgetData_excludesLockedCards() {
        let unlockedCard = makeCard(isLocked: false)
        let lockedCard = makeCard(isLocked: true)
        mockRealmManager.mockCards = [unlockedCard, lockedCard]
        let sut = makeSut()
        let expectation = XCTestExpectation(description: "Widget data refreshed")

        sut.refreshWidgetData {
            let entries = self.loadEntries()
            let lockedIds = entries.filter { $0.cardId == lockedCard.id.stringValue }
            XCTAssertTrue(lockedIds.isEmpty, "Locked cards should be excluded")

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 10)
    }

    func test_refreshWidgetData_cleanupOrphanedThumbnails() {
        let card = makeCard()
        mockRealmManager.mockCards = [card]
        let sut = makeSut()

        try? FileManager.default.createDirectory(at: thumbnailsDirectory, withIntermediateDirectories: true)
        let orphanURL = thumbnailsDirectory.appendingPathComponent("orphan_widget.jpg")
        try? Data([0xFF]).write(to: orphanURL)
        XCTAssertTrue(FileManager.default.fileExists(atPath: orphanURL.path))

        let expectation = XCTestExpectation(description: "Orphan cleanup")

        sut.refreshWidgetData {
            XCTAssertFalse(
                FileManager.default.fileExists(atPath: orphanURL.path),
                "Orphaned thumbnail should be cleaned up"
            )
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 10)
    }

    func test_refreshWidgetData_limitsThumbnailsToPoolSize() {
        let cardCount = WidgetDataManager.thumbnailPoolSize + 10
        let cards = (0..<cardCount).map { _ in makeCard() }
        mockRealmManager.mockCards = cards
        let sut = makeSut()
        let expectation = XCTestExpectation(description: "Pool size limit")

        sut.refreshWidgetData {
            let entries = self.loadEntries()
            XCTAssertEqual(entries.count, cardCount, "JSON should contain all cards")

            let withThumbnails = entries.filter { $0.thumbnailFileName != nil }
            XCTAssertLessThanOrEqual(
                withThumbnails.count,
                WidgetDataManager.thumbnailPoolSize,
                "Thumbnails should be limited to pool size"
            )

            let thumbFiles = (try? FileManager.default.contentsOfDirectory(atPath: self.thumbnailsDirectory.path)) ?? []
            XCTAssertLessThanOrEqual(
                thumbFiles.count,
                WidgetDataManager.thumbnailPoolSize,
                "Thumbnail files on disk should be limited to pool size"
            )

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 10)
    }

    func test_refreshWidgetData_alwaysIncludesOnThisDayCandidates() {
        let calendar = Calendar.current
        let today = Date()
        let todayComponents = calendar.dateComponents([.month, .day], from: today)
        var lastYearComponents = DateComponents()
        lastYearComponents.year = calendar.component(.year, from: today) - 1
        lastYearComponents.month = todayComponents.month
        lastYearComponents.day = todayComponents.day
        let lastYearDate = calendar.date(from: lastYearComponents)!

        let onThisDayCard = makeCard(date: lastYearDate)
        var otherCards = (0..<WidgetDataManager.thumbnailPoolSize + 5).map { i -> Card in
            let offset = -(i + 30)
            let date = calendar.date(byAdding: .day, value: offset, to: today)!
            return makeCard(date: date)
        }
        otherCards.append(onThisDayCard)
        mockRealmManager.mockCards = otherCards
        let sut = makeSut()
        let expectation = XCTestExpectation(description: "On this day included")

        sut.refreshWidgetData {
            let entries = self.loadEntries()
            let onThisDayEntry = entries.first { $0.cardId == onThisDayCard.id.stringValue }
            XCTAssertNotNil(onThisDayEntry, "On-this-day card should be in JSON")
            XCTAssertNotNil(
                onThisDayEntry?.thumbnailFileName,
                "On-this-day card should always have a thumbnail"
            )

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 10)
    }
}
