//
//  IsIdentifiable.swift
//  Sahara
//
//  Created by 금가경 on 9/29/25.
//

import Foundation

protocol IsIdentifiable {
    static var identifier: String { get }
}

extension IsIdentifiable {
    static var identifier: String {
        return String(describing: Self.self)
    }
}

