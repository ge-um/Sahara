//
//  MediaEditorCropHandler.swift
//  Sahara
//
//  Created by 금가경 on 10/1/25.
//

import UIKit

final class MediaEditorCropHandler {
    struct StickerDisplayLayout {
        let frame: CGRect
        let rotation: CGFloat
    }

    struct NormalizedSticker {
        let x: Double
        let y: Double
        let scale: Double
        let rotation: Double
    }

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

    static func calculateStickerDisplayLayout(
        normalizedX: Double,
        normalizedY: Double,
        scale: Double,
        rotation: Double,
        baseImageSize: CGSize,
        displayRect: CGRect,
        baseStickerSize: CGFloat = 100
    ) -> StickerDisplayLayout {
        let imageToDisplayScale = displayRect.width / baseImageSize.width

        let imageCenterX = normalizedX * baseImageSize.width
        let imageCenterY = normalizedY * baseImageSize.height

        let displayCenterX = displayRect.origin.x + (imageCenterX * imageToDisplayScale)
        let displayCenterY = displayRect.origin.y + (imageCenterY * imageToDisplayScale)
        let displaySize = baseStickerSize * scale

        let frame = CGRect(
            x: displayCenterX - displaySize / 2,
            y: displayCenterY - displaySize / 2,
            width: displaySize,
            height: displaySize
        )

        return StickerDisplayLayout(frame: frame, rotation: CGFloat(rotation))
    }

    static func normalizeStickerToImageSpace(
        centerX: CGFloat,
        centerY: CGFloat,
        scale: CGFloat,
        rotation: CGFloat,
        baseImageSize: CGSize,
        displayRect: CGRect
    ) -> NormalizedSticker {
        let displayToImageScale = baseImageSize.width / displayRect.width

        let relativeCenterX = centerX - displayRect.origin.x
        let relativeCenterY = centerY - displayRect.origin.y

        let imageCenterX = relativeCenterX * displayToImageScale
        let imageCenterY = relativeCenterY * displayToImageScale

        let normalizedX = imageCenterX / baseImageSize.width
        let normalizedY = imageCenterY / baseImageSize.height

        return NormalizedSticker(
            x: normalizedX,
            y: normalizedY,
            scale: Double(scale),
            rotation: Double(rotation)
        )
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
