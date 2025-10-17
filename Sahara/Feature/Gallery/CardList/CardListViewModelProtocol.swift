//
//  CardListViewModelProtocol.swift
//  Sahara
//
//  Created by 금가경 on 10/15/25.
//

import Foundation
import RealmSwift
import RxCocoa
import RxSwift

protocol CardListViewModelProtocol: BaseViewModelProtocol {
    associatedtype Input
    associatedtype Output

    func getCard(at index: Int) -> Card?
    func getCard(by id: ObjectId) -> Card?
}
