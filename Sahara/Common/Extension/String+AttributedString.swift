//
//  String+AttributedString.swift
//  Sahara
//
//  Created by 금가경 on 10/2/25.
//

import UIKit

extension String {
    func attributedString(
        font: UIFont,
        letterSpacing: CGFloat,
        lineSpacing: CGFloat? = nil,
        color: UIColor = .label
    ) -> NSAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        if let lineSpacing = lineSpacing {
            paragraphStyle.lineSpacing = font.pointSize / 2 * (lineSpacing - 100) / 100
        }

        var attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .kern: letterSpacing / 10,
            .foregroundColor: color
        ]

        if lineSpacing != nil {
            attributes[.paragraphStyle] = paragraphStyle
        }

        return NSAttributedString(string: self, attributes: attributes)
    }
}
