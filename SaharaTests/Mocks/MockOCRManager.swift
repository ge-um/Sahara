//
//  MockOCRManager.swift
//  SaharaTests
//
//  Created by 금가경 on 10/20/25.
//

import RxSwift
import UIKit
@testable import Sahara

final class MockOCRManager: OCRManagerProtocol {
    var recognizeTextCalled = false
    var mockOCRText: String?
    var shouldFail = false

    func recognizeText(from image: UIImage) -> Observable<String?> {
        recognizeTextCalled = true

        if shouldFail {
            return Observable.error(NSError(domain: "MockOCRError", code: -1))
        }

        return Observable.just(mockOCRText)
    }

    func reset() {
        recognizeTextCalled = false
        mockOCRText = nil
        shouldFail = false
    }
}
