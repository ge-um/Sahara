//
//  MockCardPostProcessor.swift
//  SaharaTests
//
//  Created by 금가경 on 3/13/26.
//

import Foundation
import RealmSwift
@testable import Sahara

final class MockCardPostProcessor: CardPostProcessorProtocol {
    var processCalled = false
    var processedCardId: ObjectId?
    var processedImageData: Data?
    var processUntaggedCardsCalled = false

    func process(cardId: ObjectId, imageData: Data) {
        processCalled = true
        processedCardId = cardId
        processedImageData = imageData
    }

    func processUntaggedCards() {
        processUntaggedCardsCalled = true
    }

    func reset() {
        processCalled = false
        processedCardId = nil
        processedImageData = nil
        processUntaggedCardsCalled = false
    }
}
