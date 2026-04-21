//
//  MediaEditorViewController+Crop.swift
//  Sahara
//
//  Created by 금가경 on 10/15/25.
//

import UIKit

extension MediaEditorViewController {
    func setupCropOverlay() {
        guard let uncropped = cachedUncroppedOriginalImage else { return }

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            let displayRect = ImageCoordinateSpace.displayRect(
                imageSize: uncropped.size,
                in: self.photoImageView.bounds.size
            )

            let overlayFrame = self.photoImageView.convert(self.photoImageView.bounds, to: self.view)
            self.cropOverlayView.frame = overlayFrame
            self.cropOverlayView.imageRect = displayRect

            if let lastCrop = self.lastCropRect {
                let scaledCropRect = ImageCoordinateSpace.cropRectToDisplay(
                    imagePixelCropRect: lastCrop,
                    imageSize: uncropped.size,
                    displayRect: displayRect
                )
                self.cropOverlayView.setCropRect(scaledCropRect)
            } else {
                self.cropOverlayView.setCropRect(displayRect)
            }
        }
    }

    func applyCrop() {
        guard let uncropped = cachedUncroppedOriginalImage else { return }

        let cropRectInImage = ImageCoordinateSpace.cropRectToImagePixels(
            displayCropRect: cropOverlayView.cropRect,
            imageSize: uncropped.size,
            displayRect: cropOverlayView.imageRect
        )

        lastCropRect = cropRectInImage
        applyCroppedImage(from: uncropped, cropRect: cropRectInImage)
        currentMode.accept(nil)
    }
}
