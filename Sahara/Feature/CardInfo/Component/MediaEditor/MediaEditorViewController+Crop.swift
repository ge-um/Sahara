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

            let imageRect = MediaEditorCropHandler.calculateDisplayedImageRect(
                imageSize: uncropped.size,
                in: self.photoImageView.bounds.size
            )

            let overlayFrame = self.photoImageView.convert(self.photoImageView.bounds, to: self.view)
            self.cropOverlayView.frame = overlayFrame

            let imageRectInOverlay = CGRect(
                x: imageRect.origin.x,
                y: imageRect.origin.y,
                width: imageRect.width,
                height: imageRect.height
            )

            self.cropOverlayView.imageRect = imageRectInOverlay

            if let lastCrop = self.lastCropRect {
                let scale = imageRect.width / uncropped.size.width

                let scaledCropRect = CGRect(
                    x: imageRect.origin.x + (lastCrop.origin.x * scale),
                    y: imageRect.origin.y + (lastCrop.origin.y * scale),
                    width: lastCrop.width * scale,
                    height: lastCrop.height * scale
                )

                self.cropOverlayView.setCropRect(scaledCropRect)
            } else {
                self.cropOverlayView.setCropRect(imageRectInOverlay)
            }
        }
    }

    func applyCrop() {
        guard let uncropped = cachedUncroppedOriginalImage else { return }

        let cropRectInOverlay = cropOverlayView.cropRect
        let imageRectInOverlay = cropOverlayView.imageRect

        guard let croppedImage = MediaEditorImageHandler.applyCropToImage(
            uncropped,
            cropRect: cropRectInOverlay,
            imageRect: imageRectInOverlay
        ) else {
            currentMode.accept(nil)
            return
        }

        let relativeX = cropRectInOverlay.origin.x - imageRectInOverlay.origin.x
        let relativeY = cropRectInOverlay.origin.y - imageRectInOverlay.origin.y
        let relativeWidth = cropRectInOverlay.width
        let relativeHeight = cropRectInOverlay.height

        let scale = uncropped.size.width / imageRectInOverlay.width

        let cropRectInImage = CGRect(
            x: relativeX * scale,
            y: relativeY * scale,
            width: relativeWidth * scale,
            height: relativeHeight * scale
        )

        lastCropRect = cropRectInImage
        photoImageView.image = croppedImage

        currentMode.accept(nil)
    }
}
