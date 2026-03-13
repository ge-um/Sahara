//
//  BaseViewModel.swift
//  Sahara
//
//  Created by 금가경 on 9/26/25.
//

import Foundation

protocol BaseViewModelProtocol {
    associatedtype Input
    associatedtype Output
    
    func transform(input: Input) -> Output
}
