//
//  APIRouter.swift
//  Sahara
//
//  Created by 금가경 on 9/26/25.
//

import Alamofire
import Foundation

enum APIRouter {
    case trendingStickers(page: Int, perPage: Int, customerId: String, locale: String)
    case searchStickers(query: String, page: Int, perPage: Int, customerId: String, locale: String)

    var baseURL: String {
        return APIConfig.kliPyBaseURL
    }

    var appKey: String {
        return APIConfig.kliPyAppKey
    }

    var method: HTTPMethod {
        switch self {
        case .trendingStickers, .searchStickers:
            return .get
        }
    }

    var path: String {
        switch self {
        case .trendingStickers:
            return "api/v1/\(appKey)/stickers/trending"
        case .searchStickers:
            return "api/v1/\(appKey)/stickers/search"
        }
    }

    var parameters: [String: String]? {
        switch self {
        case .trendingStickers(let page, let perPage, let customerId, let locale):
            return [
                "page": "\(page)",
                "per_page": "\(perPage)",
                "customer_id": customerId,
                "locale": locale
            ]
        case .searchStickers(let query, let page, let perPage, let customerId, let locale):
            return [
                "q": query,
                "page": "\(page)",
                "per_page": "\(perPage)",
                "customer_id": customerId,
                "locale": locale
            ]
        }
    }

    var endPoint: URL? {
        guard var components = URLComponents(string: baseURL + path) else {
            return nil
        }

        if let params = parameters {
            components.queryItems = params.map { URLQueryItem(name: $0.key, value: $0.value) }
        }

        return components.url
    }
}
