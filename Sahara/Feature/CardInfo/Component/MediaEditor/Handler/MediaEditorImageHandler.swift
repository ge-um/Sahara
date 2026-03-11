//
//  MediaEditorImageHandler.swift
//  Sahara
//
//  Created by 금가경 on 10/15/25.
//

import Kingfisher
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

        let hasAlpha: Bool
        if let alphaInfo = baseImage.cgImage?.alphaInfo {
            hasAlpha = !(alphaInfo == .none || alphaInfo == .noneSkipFirst || alphaInfo == .noneSkipLast)
        } else {
            hasAlpha = false
        }

        let screenScale = photoImageView.window?.screen.scale ?? 2.0
        let format = UIGraphicsImageRendererFormat()
        format.scale = screenScale
        format.opaque = !hasAlpha

        let renderer = UIGraphicsImageRenderer(size: imageRect.size, format: format)
        let image = renderer.image { context in
            if hasAlpha {
                context.cgContext.clear(CGRect(origin: .zero, size: imageRect.size))
            }
            context.cgContext.translateBy(x: -imageRect.origin.x, y: -imageRect.origin.y)
            photoImageView.layer.render(in: context.cgContext)
            stickerContainerView.layer.render(in: context.cgContext)

            let drawingImage = canvasView.drawing.image(from: canvasView.bounds, scale: screenScale)
            drawingImage.draw(at: .zero)
        }

        return image
    }

    static func compositeStickersOnImage(_ baseImage: UIImage, stickers: [StickerDTO], editorViewSize: CGSize? = nil, completion: @escaping (UIImage, [Bool]) -> Void) {
        let imageSize = baseImage.size
        let group = DispatchGroup()
        let syncQueue = DispatchQueue(label: "com.sahara.stickerSync")
        var stickerImages: [(image: UIImage, sticker: StickerDTO, isAnimated: Bool)] = []

        for sticker in stickers.sorted(by: { $0.zIndex < $1.zIndex }) {
            group.enter()

            if let resourceUrl = sticker.resourceUrl, let url = URL(string: resourceUrl) {
                let isAnimatedGif = url.pathExtension.lowercased() == "gif"

                if let cached = ImageCache.default.retrieveImageInMemoryCache(forKey: url.absoluteString) {
                    syncQueue.async {
                        stickerImages.append((cached, sticker, isAnimatedGif))
                        group.leave()
                    }
                } else {
                    KingfisherManager.shared.retrieveImage(with: url) { result in
                        syncQueue.async {
                            switch result {
                            case .success(let imageResult):
                                stickerImages.append((imageResult.image, sticker, isAnimatedGif))
                            case .failure:
                                break
                            }
                            group.leave()
                        }
                    }
                }
            } else if let localPath = sticker.localFilePath {
                let fileURL = URL(fileURLWithPath: localPath)
                let isAnimatedGif = fileURL.pathExtension.lowercased() == "gif"

                if let cached = ImageCache.default.retrieveImageInMemoryCache(forKey: fileURL.absoluteString) {
                    syncQueue.async {
                        stickerImages.append((cached, sticker, isAnimatedGif))
                        group.leave()
                    }
                } else {
                    KingfisherManager.shared.retrieveImage(with: fileURL) { result in
                        syncQueue.async {
                            switch result {
                            case .success(let imageResult):
                                stickerImages.append((imageResult.image, sticker, isAnimatedGif))
                            case .failure:
                                break
                            }
                            group.leave()
                        }
                    }
                }
            } else {
                group.leave()
            }
        }

        group.notify(queue: .global(qos: .userInitiated)) {
            let viewSize: CGSize
            if let editorSize = editorViewSize {
                viewSize = editorSize
            } else {
                let screenWidth = (UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first?.screen.bounds.width) ?? 393
                let standardCardWidth = min(screenWidth - 64, 400)
                viewSize = CGSize(width: standardCardWidth, height: standardCardWidth * 2)
            }
            let displayRect = MediaEditorCropHandler.calculateDisplayedImageRect(
                imageSize: imageSize,
                in: viewSize
            )
            let displayToImageScale = imageSize.width / displayRect.width
            let baseStickerSize: CGFloat = 100

            let hasAlpha: Bool
            if let alphaInfo = baseImage.cgImage?.alphaInfo {
                hasAlpha = !(alphaInfo == .none || alphaInfo == .noneSkipFirst || alphaInfo == .noneSkipLast)
            } else {
                hasAlpha = false
            }

            let format = UIGraphicsImageRendererFormat()
            format.scale = 1.0
            format.opaque = !hasAlpha

            let renderer = UIGraphicsImageRenderer(size: imageSize, format: format)
            let compositedImage = renderer.image { context in
                if hasAlpha {
                    context.cgContext.clear(CGRect(origin: .zero, size: imageSize))
                }
                baseImage.draw(at: .zero)

                for item in stickerImages.sorted(by: { $0.sticker.zIndex < $1.sticker.zIndex }) {
                    let sticker = item.sticker
                    let image = item.image

                    let stickerFrameSize = baseStickerSize * sticker.scale * displayToImageScale
                    let stickerAspect = image.size.width / image.size.height
                    let width: CGFloat
                    let height: CGFloat
                    if stickerAspect >= 1 {
                        width = stickerFrameSize
                        height = stickerFrameSize / stickerAspect
                    } else {
                        width = stickerFrameSize * stickerAspect
                        height = stickerFrameSize
                    }
                    let centerX = sticker.x * imageSize.width
                    let centerY = sticker.y * imageSize.height

                    let rect = CGRect(
                        x: centerX - width / 2,
                        y: centerY - height / 2,
                        width: width,
                        height: height
                    )

                    context.cgContext.saveGState()
                    context.cgContext.translateBy(x: centerX, y: centerY)
                    context.cgContext.rotate(by: sticker.rotation)
                    context.cgContext.translateBy(x: -centerX, y: -centerY)
                    image.draw(in: rect)
                    context.cgContext.restoreGState()
                }
            }

            let isAnimatedFlags = stickerImages.map { $0.isAnimated }
            DispatchQueue.main.async {
                completion(compositedImage, isAnimatedFlags)
            }
        }
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
