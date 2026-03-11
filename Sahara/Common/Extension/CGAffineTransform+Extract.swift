//
//  CGAffineTransform+Extract.swift
//  Sahara
//

import CoreGraphics

extension CGAffineTransform {
    var extractedScale: CGFloat {
        sqrt(a * a + c * c)
    }

    var extractedRotation: CGFloat {
        atan2(b, a)
    }
}
