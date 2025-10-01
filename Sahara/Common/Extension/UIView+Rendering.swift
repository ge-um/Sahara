//
//  UIView+Rendering.swift
//  Sahara
//
//  Created by 금가경 on 9/26/25.
//

import UIKit

extension UIView {
    func asImage() -> UIImage? {
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image { context in
            layer.render(in: context.cgContext)
        }
    }
}
