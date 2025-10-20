//
//  NetworkManagerProtocol.swift
//  Sahara
//
//  Created by 금가경 on 10/21/25.
//

import Foundation
import RxSwift

protocol NetworkManagerProtocol {
    func callRequest<T: Decodable>(api: APIRouter, type: T.Type) -> Observable<T>
}
