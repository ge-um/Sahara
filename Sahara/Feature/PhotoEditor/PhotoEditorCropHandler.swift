//
//  PhotoEditorCropHandler.swift
//  Sahara
//
//  Created by 금가경 on 10/1/25.
//

import UIKit

final class PhotoEditorCropHandler {
    static func calculateDisplayedImageRect(
        imageSize: CGSize,
        in viewSize: CGSize
    ) -> CGRect {
        let imageAspect = imageSize.width / imageSize.height
        let viewAspect = viewSize.width / viewSize.height

        var imageRect = CGRect.zero

        if imageAspect > viewAspect {
            let displayHeight = viewSize.width / imageAspect
            imageRect = CGRect(
                x: 0,
                y: (viewSize.height - displayHeight) / 2,
                width: viewSize.width,
                height: displayHeight
            )
        } else {
            let displayWidth = viewSize.height * imageAspect
            imageRect = CGRect(
                x: (viewSize.width - displayWidth) / 2,
                y: 0,
                width: displayWidth,
                height: viewSize.height
            )
        }

        return imageRect
    }

    static func convertCropRectToImageCoordinates(
        cropRect: CGRect,
        imageSize: CGSize,
        displayedImageRect: CGRect
    ) -> CGRect {
        let scaleX = imageSize.width / displayedImageRect.width
        let scaleY = imageSize.height / displayedImageRect.height

        return CGRect(
            x: (cropRect.origin.x - displayedImageRect.origin.x) * scaleX,
            y: (cropRect.origin.y - displayedImageRect.origin.y) * scaleY,
            width: cropRect.size.width * scaleX,
            height: cropRect.size.height * scaleY
        )
    }

    static func cropImage(
        _ image: UIImage,
        to cropRect: CGRect
    ) -> UIImage? {
        guard let cgImage = image.cgImage?.cropping(to: cropRect) else {
            return nil
        }

        return UIImage(
            cgImage: cgImage,
            scale: image.scale,
            orientation: image.imageOrientation
        )
    }
}
