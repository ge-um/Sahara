//
//  UIColor+DesignToken.swift
//  Sahara
//
//  Created by 금가경 on 3/4/26.
//

import UIKit

extension UIColor {
    static func token(_ token: DesignToken.Color) -> UIColor {
        token.uiColor
    }
}
