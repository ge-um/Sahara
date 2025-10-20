//
//  MockNetworkManager.swift
//  SaharaTests
//
//  Created by 금가경 on 10/21/25.
//

import Foundation
import RxSwift
@testable import Sahara

final class MockNetworkManager: NetworkManagerProtocol {
    var shouldReturnError = false
    var errorToReturn: Error = NetworkError.invalidURL
    var mockResponse: Any?
    var callCount = 0
    var lastAPIRouter: APIRouter?

    func callRequest<T: Decodable>(api: APIRouter, type: T.Type) -> Observable<T> {
        callCount += 1
        lastAPIRouter = api

        if shouldReturnError {
            return Observable.error(errorToReturn)
        }

        guard let response = mockResponse as? T else {
            return Observable.error(NetworkError.decodingError)
        }

        return Observable.just(response)
    }
}
