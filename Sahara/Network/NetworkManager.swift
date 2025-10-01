//
//  NetworkManager.swift
//  Sahara
//
//  Created by 금가경 on 9/26/25.
//

import Alamofire
import Foundation
import RxSwift

final class NetworkManager {
    static let shared = NetworkManager()

    private init() {}

    func callRequest<T: Decodable>(api: APIRouter, type: T.Type) -> Observable<T> {
        return Observable.create { observer in
            guard let url = api.endPoint else {
                observer.onError(NetworkError.invalidURL)
                return Disposables.create()
            }

            AF.request(url, method: api.method)
                .validate()
                .responseDecodable(of: T.self) { response in
                    switch response.result {
                    case .success(let data):
                        observer.onNext(data)
                        observer.onCompleted()
                    case .failure(let error):
                        if let urlError = error.underlyingError as? URLError {
                            if urlError.code == .notConnectedToInternet {
                                observer.onError(NetworkError.notConnectedToInternet)
                                return
                            }
                        }
                        observer.onError(error)
                    }
                }

            return Disposables.create()
        }
    }
}

enum NetworkError: Error {
    case invalidURL
    case notConnectedToInternet
    case decodingError

    var errorDescription: String {
        switch self {
        case .invalidURL:
            return "잘못된 URL입니다."
        case .notConnectedToInternet:
            return "네트워크 연결이 일시적으로 원활하지 않습니다. 데이터 또는 Wi-fi 연결 상태를 확인해 주세요."
        case .decodingError:
            return "데이터 처리 중 오류가 발생했습니다."
        }
    }
}