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

    func normalizedOrientation() -> UIImage {
        guard imageOrientation != .up else { return self }

        let format = UIGraphicsImageRendererFormat()
        format.scale = scale

        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: size))
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

        var options: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: compressionQuality
        ]

        if imageOrientation != .up {
            let cgOrientation = CGImagePropertyOrientation(imageOrientation)
            options[kCGImagePropertyOrientation] = cgOrientation.rawValue
        }

        CGImageDestinationAddImage(destination, cgImage, options as CFDictionary)
        guard CGImageDestinationFinalize(destination) else {
            return nil
        }

        return mutableData as Data
    }
}

private extension CGImagePropertyOrientation {
    init(_ uiOrientation: UIImage.Orientation) {
        switch uiOrientation {
        case .up: self = .up
        case .upMirrored: self = .upMirrored
        case .down: self = .down
        case .downMirrored: self = .downMirrored
        case .left: self = .left
        case .leftMirrored: self = .leftMirrored
        case .right: self = .right
        case .rightMirrored: self = .rightMirrored
        @unknown default: self = .up
        }
    }
}
