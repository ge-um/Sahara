//
//  UIView+Rendering.swift
//  Sahara
//
//  Created by 금가경 on 9/26/25.
//

import UIKit

extension UIView {
    func asImage() -> UIImage? {
        let format = UIGraphicsImageRendererFormat()
        format.opaque = isOpaque
        let renderer = UIGraphicsImageRenderer(bounds: bounds, format: format)
        return renderer.image { context in
            layer.render(in: context.cgContext)
        }
    }
}
