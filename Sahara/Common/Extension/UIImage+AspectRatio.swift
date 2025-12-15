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

    func resized(maxDimension: CGFloat? = nil) -> UIImage {
        let screenBounds = UIScreen.main.bounds
        let screenScale = UIScreen.main.scale
        let maxScreenDimension = max(screenBounds.width, screenBounds.height)
        let targetMaxDimension = maxDimension ?? (maxScreenDimension * screenScale * 2)

        let maxCurrentDimension = max(size.width * scale, size.height * scale)
        guard maxCurrentDimension > targetMaxDimension else {
            return self
        }

        let aspectRatio = size.width / size.height
        let newSize: CGSize
        if size.width > size.height {
            newSize = CGSize(width: targetMaxDimension, height: targetMaxDimension / aspectRatio)
        } else {
            newSize = CGSize(width: targetMaxDimension * aspectRatio, height: targetMaxDimension)
        }

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0

        let hasAlpha: Bool
        if let alphaInfo = cgImage?.alphaInfo {
            hasAlpha = !(alphaInfo == .none || alphaInfo == .noneSkipFirst || alphaInfo == .noneSkipLast)
        } else {
            hasAlpha = false
        }
        format.opaque = !hasAlpha

        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        return renderer.image { context in
            if hasAlpha {
                context.cgContext.clear(CGRect(origin: .zero, size: newSize))
            }
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
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
