//
//  UIFont+DesignToken.swift
//  Sahara
//
//  Created by 금가경 on 3/28/26.
//

import UIKit

extension UIFont {
    static func typography(_ token: DesignToken.Typography) -> UIFont {
        token.font
    }
}
