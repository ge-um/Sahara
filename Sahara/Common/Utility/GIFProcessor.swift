//
//  GIFProcessor.swift
//  Sahara
//
//  Created by 금가경 on 12/07/25.
//

import UIKit
import ImageIO

final class GIFProcessor {
    static func extractFirstFrame(from data: Data) -> UIImage? {
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, nil),
              CGImageSourceGetCount(imageSource) > 0,
              let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
            return nil
        }
        return UIImage(cgImage: cgImage)
    }

    static func isAnimatedGIF(data: Data) -> Bool {
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, nil) else {
            return false
        }
        return CGImageSourceGetCount(imageSource) > 1
    }
}
