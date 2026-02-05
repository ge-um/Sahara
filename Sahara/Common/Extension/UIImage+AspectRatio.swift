//
//  UIImage+AspectRatio.swift
//  Sahara
//
//  Created by 금가경 on 9/26/25.
//

import UIKit
import ImageIO

extension UIImage {
    func heightForWidth(_ width: CGFloat) -> CGFloat {
        let aspectRatio = size.height / size.width
        return width * aspectRatio
    }

    func heicData(compressionQuality: CGFloat = 0.8) -> Data? {
        guard let mutableData = CFDataCreateMutable(nil, 0),
              let destination = CGImageDestinationCreateWithData(
                  mutableData,
                  "public.heic" as CFString,
                  1,
                  nil
              ),
              let cgImage = self.cgImage else {
            return nil
        }

        let options: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: compressionQuality
        ]

        CGImageDestinationAddImage(destination, cgImage, options as CFDictionary)
        guard CGImageDestinationFinalize(destination) else {
            return nil
        }

        return mutableData as Data
    }
}
