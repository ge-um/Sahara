//
//  MediaEditorImageHandler.swift
//  Sahara
//
//  Created by 금가경 on 10/15/25.
//

import PencilKit
import UIKit

final class MediaEditorImageHandler {
    static func generateFinalImage(
        photoImageView: UIImageView,
        stickerContainerView: UIView,
        canvasView: PKCanvasView
    ) -> UIImage {
        guard let baseImage = photoImageView.image else {
            return UIImage()
        }

        let imageRect = MediaEditorCropHandler.calculateDisplayedImageRect(
            imageSize: baseImage.size,
            in: photoImageView.bounds.size
        )

        let renderer = UIGraphicsImageRenderer(size: imageRect.size)
        let image = renderer.image { context in
            context.cgContext.translateBy(x: -imageRect.origin.x, y: -imageRect.origin.y)
            photoImageView.layer.render(in: context.cgContext)

            let drawingImage = canvasView.drawing.image(from: canvasView.bounds, scale: UIScreen.main.scale)
            drawingImage.draw(at: .zero)
        }

        return image
    }

    static func applyCropToImage(_ uncropped: UIImage, cropRect: CGRect, imageRect: CGRect) -> UIImage? {
        let relativeX = cropRect.origin.x - imageRect.origin.x
        let relativeY = cropRect.origin.y - imageRect.origin.y
        let relativeWidth = cropRect.width
        let relativeHeight = cropRect.height

        let scale = uncropped.size.width / imageRect.width

        let cropRectInImage = CGRect(
            x: relativeX * scale,
            y: relativeY * scale,
            width: relativeWidth * scale,
            height: relativeHeight * scale
        )

        let normalizedImage: UIImage
        if uncropped.imageOrientation != .up {
            UIGraphicsBeginImageContextWithOptions(uncropped.size, false, uncropped.scale)
            uncropped.draw(in: CGRect(origin: .zero, size: uncropped.size))
            normalizedImage = UIGraphicsGetImageFromCurrentImageContext() ?? uncropped
            UIGraphicsEndImageContext()
        } else {
            normalizedImage = uncropped
        }

        guard let normalizedCGImage = normalizedImage.cgImage,
              let croppedCGImage = normalizedCGImage.cropping(to: cropRectInImage) else {
            return nil
        }

        let croppedImage = UIImage(
            cgImage: croppedCGImage,
            scale: normalizedImage.scale,
            orientation: .up
        )

        return croppedImage
    }
}
