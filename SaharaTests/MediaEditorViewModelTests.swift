//
//  MediaEditorViewModelTests.swift
//  SaharaTests
//
//  Created by 금가경 on 10/21/25.
//

import XCTest
import RxSwift
import RxCocoa
@testable import Sahara

final class MediaEditorViewModelTests: XCTestCase {
    private var sut: MediaEditorViewModel!
    private var mockNetworkService: MockNetworkService!
    private var disposeBag: DisposeBag!
    private var testImage: UIImage!

    override func setUp() {
        super.setUp()
        mockNetworkService = MockNetworkService()
        testImage = UIImage(systemName: "photo")!
        let imageSource = ImageSourceData(image: testImage, format: nil, stickers: [])
        sut = MediaEditorViewModel(imageSource: imageSource, networkManager: mockNetworkService)
        disposeBag = DisposeBag()
    }

    override func tearDown() {
        sut = nil
        mockNetworkService = nil
        disposeBag = nil
        testImage = nil
        super.tearDown()
    }

    func test_viewWillAppear_shouldLoadTrendingStickers() {
        let mockStickers = createMockStickers(count: 3)
        let mockResponse = StickerResponse(
            result: true,
            data: StickerData(
                data: mockStickers,
                currentPage: 1,
                perPage: 20,
                hasNext: true
            )
        )
        mockNetworkService.mockResponse = mockResponse

        let viewWillAppear = PublishSubject<Void>()
        let input = MediaEditorViewModel.Input(
            viewWillAppear: viewWillAppear.asObservable(),
            stickerButtonTapped: .empty(),
            searchQuery: .empty(),
            loadMoreTrigger: .empty(),
            stickerSelected: .empty(),
            stickerAdded: .empty(),
            filterSelected: .empty(),
            cropApplied: .empty(),
            drawingChanged: .empty(),
            photoSelected: .empty(),
            doneButtonTapped: .empty(),
            cancelButtonTapped: .empty()
        )

        let output = sut.transform(input: input)
        let expectation = XCTestExpectation(description: "Load trending stickers")

        output.stickers
            .skip(1)
            .drive(onNext: { stickers in
                XCTAssertEqual(stickers.count, 3)
                XCTAssertEqual(self.mockNetworkService.callCount, 1)
                expectation.fulfill()
            })
            .disposed(by: disposeBag)

        viewWillAppear.onNext(())

        wait(for: [expectation], timeout: 2.0)
    }

    func test_searchQuery_shouldCallSearchAPI() {
        let mockStickers = createMockStickers(count: 2)
        let mockResponse = StickerResponse(
            result: true,
            data: StickerData(
                data: mockStickers,
                currentPage: 1,
                perPage: 20,
                hasNext: false
            )
        )
        mockNetworkService.mockResponse = mockResponse

        let searchQuery = PublishSubject<String>()
        let input = MediaEditorViewModel.Input(
            viewWillAppear: .empty(),
            stickerButtonTapped: .empty(),
            searchQuery: searchQuery.asObservable(),
            loadMoreTrigger: .empty(),
            stickerSelected: .empty(),
            stickerAdded: .empty(),
            filterSelected: .empty(),
            cropApplied: .empty(),
            drawingChanged: .empty(),
            photoSelected: .empty(),
            doneButtonTapped: .empty(),
            cancelButtonTapped: .empty()
        )

        let output = sut.transform(input: input)
        let expectation = XCTestExpectation(description: "Search stickers")

        output.stickers
            .skip(1)
            .drive(onNext: { stickers in
                XCTAssertEqual(stickers.count, 2)
                XCTAssertEqual(self.mockNetworkService.callCount, 1)
                expectation.fulfill()
            })
            .disposed(by: disposeBag)

        searchQuery.onNext("")
        searchQuery.onNext("cat")

        wait(for: [expectation], timeout: 2.0)
    }

    func test_emptySearchQuery_shouldLoadTrendingStickers() {
        let mockStickers = createMockStickers(count: 5)
        let mockResponse = StickerResponse(
            result: true,
            data: StickerData(
                data: mockStickers,
                currentPage: 1,
                perPage: 20,
                hasNext: true
            )
        )
        mockNetworkService.mockResponse = mockResponse

        let searchQuery = PublishSubject<String>()
        let input = MediaEditorViewModel.Input(
            viewWillAppear: .empty(),
            stickerButtonTapped: .empty(),
            searchQuery: searchQuery.asObservable(),
            loadMoreTrigger: .empty(),
            stickerSelected: .empty(),
            stickerAdded: .empty(),
            filterSelected: .empty(),
            cropApplied: .empty(),
            drawingChanged: .empty(),
            photoSelected: .empty(),
            doneButtonTapped: .empty(),
            cancelButtonTapped: .empty()
        )

        let output = sut.transform(input: input)
        let expectation = XCTestExpectation(description: "Load trending on empty query")

        output.stickers
            .skip(1)
            .drive(onNext: { stickers in
                XCTAssertEqual(stickers.count, 5)
                expectation.fulfill()
            })
            .disposed(by: disposeBag)

        searchQuery.onNext("cat")
        searchQuery.onNext("")

        wait(for: [expectation], timeout: 2.0)
    }

    func test_loadMore_shouldAppendStickers() {
        let firstPageStickers = createMockStickers(count: 3)
        let secondPageStickers = createMockStickers(count: 2, startId: 4)

        let firstResponse = StickerResponse(
            result: true,
            data: StickerData(
                data: firstPageStickers,
                currentPage: 1,
                perPage: 20,
                hasNext: true
            )
        )

        let secondResponse = StickerResponse(
            result: true,
            data: StickerData(
                data: secondPageStickers,
                currentPage: 2,
                perPage: 20,
                hasNext: false
            )
        )

        let viewWillAppear = PublishSubject<Void>()
        let loadMore = PublishSubject<Void>()
        let input = MediaEditorViewModel.Input(
            viewWillAppear: viewWillAppear.asObservable(),
            stickerButtonTapped: .empty(),
            searchQuery: .empty(),
            loadMoreTrigger: loadMore.asObservable(),
            stickerSelected: .empty(),
            stickerAdded: .empty(),
            filterSelected: .empty(),
            cropApplied: .empty(),
            drawingChanged: .empty(),
            photoSelected: .empty(),
            doneButtonTapped: .empty(),
            cancelButtonTapped: .empty()
        )

        let output = sut.transform(input: input)
        var resultCount = 0
        let expectation = XCTestExpectation(description: "Load more stickers")

        output.stickers
            .skip(1)
            .drive(onNext: { stickers in
                resultCount += 1
                if resultCount == 1 {
                    XCTAssertEqual(stickers.count, 3)
                    self.mockNetworkService.mockResponse = secondResponse
                    loadMore.onNext(())
                } else if resultCount == 2 {
                    XCTAssertEqual(stickers.count, 5)
                    XCTAssertEqual(self.mockNetworkService.callCount, 2)
                    expectation.fulfill()
                }
            })
            .disposed(by: disposeBag)

        mockNetworkService.mockResponse = firstResponse
        viewWillAppear.onNext(())

        wait(for: [expectation], timeout: 3.0)
    }

    func test_networkError_shouldEmitErrorMessage() {
        mockNetworkService.shouldReturnError = true
        mockNetworkService.errorToReturn = NetworkError.notConnectedToInternet

        let viewWillAppear = PublishSubject<Void>()
        let input = MediaEditorViewModel.Input(
            viewWillAppear: viewWillAppear.asObservable(),
            stickerButtonTapped: .empty(),
            searchQuery: .empty(),
            loadMoreTrigger: .empty(),
            stickerSelected: .empty(),
            stickerAdded: .empty(),
            filterSelected: .empty(),
            cropApplied: .empty(),
            drawingChanged: .empty(),
            photoSelected: .empty(),
            doneButtonTapped: .empty(),
            cancelButtonTapped: .empty()
        )

        let output = sut.transform(input: input)
        let expectation = XCTestExpectation(description: "Error message emitted")

        output.errorMessage
            .drive(onNext: { errorMessage in
                XCTAssertFalse(errorMessage.isEmpty)
                XCTAssertEqual(errorMessage, NetworkError.notConnectedToInternet.errorDescription)
                expectation.fulfill()
            })
            .disposed(by: disposeBag)

        viewWillAppear.onNext(())

        wait(for: [expectation], timeout: 2.0)
    }

    func test_searchError_shouldEmitErrorMessage() {
        let mockStickers = createMockStickers(count: 1)
        let mockResponse = StickerResponse(
            result: true,
            data: StickerData(
                data: mockStickers,
                currentPage: 1,
                perPage: 20,
                hasNext: false
            )
        )
        mockNetworkService.mockResponse = mockResponse

        let searchQuery = PublishSubject<String>()
        let input = MediaEditorViewModel.Input(
            viewWillAppear: .empty(),
            stickerButtonTapped: .empty(),
            searchQuery: searchQuery.asObservable(),
            loadMoreTrigger: .empty(),
            stickerSelected: .empty(),
            stickerAdded: .empty(),
            filterSelected: .empty(),
            cropApplied: .empty(),
            drawingChanged: .empty(),
            photoSelected: .empty(),
            doneButtonTapped: .empty(),
            cancelButtonTapped: .empty()
        )

        let output = sut.transform(input: input)
        let expectation = XCTestExpectation(description: "Search error")

        output.errorMessage
            .drive(onNext: { errorMessage in
                if !errorMessage.isEmpty {
                    XCTAssertEqual(errorMessage, NetworkError.invalidURL.errorDescription)
                    expectation.fulfill()
                }
            })
            .disposed(by: disposeBag)

        searchQuery.onNext("")
        mockNetworkService.shouldReturnError = true
        mockNetworkService.errorToReturn = NetworkError.invalidURL
        searchQuery.onNext("test")

        wait(for: [expectation], timeout: 2.0)
    }

    private func createMockStickers(count: Int, startId: Int = 1) -> [KlipySticker] {
        return (startId..<startId + count).map { id in
            KlipySticker(
                id: id,
                slug: "sticker-\(id)",
                title: "Sticker \(id)",
                blurPreview: nil,
                file: StickerFile(
                    hd: StickerQuality(
                        gif: StickerImageInfo(url: "https://example.com/sticker-\(id).gif", width: 500, height: 500, size: 1024),
                        webp: nil,
                        mp4: nil
                    ),
                    md: nil,
                    sm: nil,
                    xs: nil
                ),
                tags: ["tag1", "tag2"],
                type: "sticker"
            )
        }
    }
}
