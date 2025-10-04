//
//  UIImage+AspectRatio.swift
//  Sahara
//
//  Created by 금가경 on 9/26/25.
//

import UIKit

extension UIImage {
    func heightForWidth(_ width: CGFloat) -> CGFloat {
        let aspectRatio = size.height / size.width
        return width * aspectRatio
    }
}
