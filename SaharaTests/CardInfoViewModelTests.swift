//
//  CardInfoViewModelTests.swift
//  SaharaTests
//
//  Created by 금가경 on 10/20/25.
//

import CoreLocation
import RxSwift
import XCTest
@testable import Sahara

final class CardInfoViewModelTests: XCTestCase {
    var sut: CardInfoViewModel!
    var mockRealmManager: MockRealmManager!
    var mockCardPostProcessor: MockCardPostProcessor!
    var disposeBag: DisposeBag!

    override func setUp() {
        super.setUp()
        disposeBag = DisposeBag()
        mockRealmManager = MockRealmManager()
        mockCardPostProcessor = MockCardPostProcessor()
    }

    override func tearDown() {
        sut = nil
        mockRealmManager = nil
        mockCardPostProcessor = nil
        disposeBag = nil
        super.tearDown()
    }

    private func createTestImage() -> UIImage {
        let size = CGSize(width: 1, height: 1)
        UIGraphicsBeginImageContext(size)
        defer { UIGraphicsEndImageContext() }

        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(UIColor.red.cgColor)
        context?.fill(CGRect(origin: .zero, size: size))

        return UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
    }

    func test_saveWithImage_shouldCallRealmManagerAdd() {
        let testImage = createTestImage()
        sut = CardInfoViewModel(editedImage: testImage, realmManager: mockRealmManager, cardPostProcessor: mockCardPostProcessor)

        let saveButtonTapped = PublishSubject<Void>()

        let input = CardInfoViewModel.Input(
            selectedImage: .just(testImage),
            imageSourceData: .just(nil),
            date: .just(Date()),
            memo: .just("Test memo"),
            customFolder: .just(nil),
            location: .empty(),
            isLocked: .just(false),
            saveButtonTapped: saveButtonTapped.asObservable(),
            cancelButtonTapped: .empty(),
            deleteButtonTapped: .empty()
        )

        let output = sut.transform(input: input)

        let expectation = XCTestExpectation(description: "Save completed")

        output.saved
            .drive(onNext: { success in
                if success {
                    expectation.fulfill()
                }
            })
            .disposed(by: disposeBag)

        saveButtonTapped.onNext(())

        wait(for: [expectation], timeout: 2.0)
        XCTAssertTrue(mockRealmManager.addCalled)
    }

    func test_cancelButton_shouldEmitDismiss() {
        sut = CardInfoViewModel(editedImage: nil, realmManager: mockRealmManager, cardPostProcessor: mockCardPostProcessor)

        let cancelButtonTapped = PublishSubject<Void>()

        let input = CardInfoViewModel.Input(
            selectedImage: .empty(),
            imageSourceData: .just(nil),
            date: .empty(),
            memo: .empty(),
            customFolder: .empty(),
            location: .empty(),
            isLocked: .empty(),
            saveButtonTapped: .empty(),
            cancelButtonTapped: cancelButtonTapped.asObservable(),
            deleteButtonTapped: .empty()
        )

        let output = sut.transform(input: input)

        let expectation = XCTestExpectation(description: "Dismiss emitted")

        output.dismiss
            .drive(onNext: { _ in
                expectation.fulfill()
            })
            .disposed(by: disposeBag)

        cancelButtonTapped.onNext(())

        wait(for: [expectation], timeout: 1.0)
    }

    func test_selectedImage_shouldUpdateHasImage() {
        sut = CardInfoViewModel(editedImage: nil, realmManager: mockRealmManager, cardPostProcessor: mockCardPostProcessor)

        let selectedImage = BehaviorSubject<UIImage?>(value: nil)

        let input = CardInfoViewModel.Input(
            selectedImage: selectedImage.asObservable(),
            imageSourceData: .just(nil),
            date: .empty(),
            memo: .empty(),
            customFolder: .empty(),
            location: .empty(),
            isLocked: .empty(),
            saveButtonTapped: .empty(),
            cancelButtonTapped: .empty(),
            deleteButtonTapped: .empty()
        )

        let output = sut.transform(input: input)

        let expectation = XCTestExpectation(description: "Has image updated")

        output.hasImage
            .skip(1)
            .drive(onNext: { hasImage in
                if hasImage {
                    expectation.fulfill()
                }
            })
            .disposed(by: disposeBag)

        selectedImage.onNext(createTestImage())

        wait(for: [expectation], timeout: 1.0)
    }

    func test_saveWithImage_shouldTriggerPostProcessing() {
        let testImage = createTestImage()
        sut = CardInfoViewModel(editedImage: testImage, realmManager: mockRealmManager, cardPostProcessor: mockCardPostProcessor)

        let saveButtonTapped = PublishSubject<Void>()

        let input = CardInfoViewModel.Input(
            selectedImage: .just(testImage),
            imageSourceData: .just(nil),
            date: .just(Date()),
            memo: .just("Test memo"),
            customFolder: .just(nil),
            location: .empty(),
            isLocked: .just(false),
            saveButtonTapped: saveButtonTapped.asObservable(),
            cancelButtonTapped: .empty(),
            deleteButtonTapped: .empty()
        )

        let output = sut.transform(input: input)

        let expectation = XCTestExpectation(description: "Save completed")

        output.saved
            .drive(onNext: { success in
                if success {
                    expectation.fulfill()
                }
            })
            .disposed(by: disposeBag)

        saveButtonTapped.onNext(())

        wait(for: [expectation], timeout: 2.0)
        XCTAssertTrue(mockCardPostProcessor.processCalled)
        XCTAssertNotNil(mockCardPostProcessor.processedCardId)
        XCTAssertNotNil(mockCardPostProcessor.processedImageData)
    }

    func test_isEditMode_shouldBeFalseForNewCard() {
        sut = CardInfoViewModel(editedImage: nil, realmManager: mockRealmManager, cardPostProcessor: mockCardPostProcessor)

        let output = sut.transform(input: CardInfoViewModel.Input(
            selectedImage: .empty(),
            imageSourceData: .just(nil),
            date: .empty(),
            memo: .empty(),
            customFolder: .empty(),
            location: .empty(),
            isLocked: .empty(),
            saveButtonTapped: .empty(),
            cancelButtonTapped: .empty(),
            deleteButtonTapped: .empty()
        ))

        XCTAssertFalse(output.isEditMode)
    }
}
