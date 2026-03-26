import CoreGraphics

enum ImageCoordinateSpace {

    static func displayRect(imageSize: CGSize, in viewSize: CGSize) -> CGRect {
        let imageAspect = imageSize.width / imageSize.height
        let viewAspect = viewSize.width / viewSize.height

        if imageAspect > viewAspect {
            let displayHeight = viewSize.width / imageAspect
            return CGRect(
                x: 0,
                y: (viewSize.height - displayHeight) / 2,
                width: viewSize.width,
                height: displayHeight
            )
        } else {
            let displayWidth = viewSize.height * imageAspect
            return CGRect(
                x: (viewSize.width - displayWidth) / 2,
                y: 0,
                width: displayWidth,
                height: viewSize.height
            )
        }
    }

    static func toImagePixels(
        displayCenter: CGPoint,
        imageSize: CGSize,
        displayRect: CGRect
    ) -> CGPoint {
        let scaleX = imageSize.width / displayRect.width
        let scaleY = imageSize.height / displayRect.height
        return CGPoint(
            x: (displayCenter.x - displayRect.origin.x) * scaleX,
            y: (displayCenter.y - displayRect.origin.y) * scaleY
        )
    }

    static func toDisplayCenter(
        imagePixels: CGPoint,
        imageSize: CGSize,
        displayRect: CGRect
    ) -> CGPoint {
        let scaleX = displayRect.width / imageSize.width
        let scaleY = displayRect.height / imageSize.height
        return CGPoint(
            x: displayRect.origin.x + imagePixels.x * scaleX,
            y: displayRect.origin.y + imagePixels.y * scaleY
        )
    }

    static func cropRectToImagePixels(
        displayCropRect: CGRect,
        imageSize: CGSize,
        displayRect: CGRect
    ) -> CGRect {
        let scaleX = imageSize.width / displayRect.width
        let scaleY = imageSize.height / displayRect.height
        return CGRect(
            x: (displayCropRect.origin.x - displayRect.origin.x) * scaleX,
            y: (displayCropRect.origin.y - displayRect.origin.y) * scaleY,
            width: displayCropRect.width * scaleX,
            height: displayCropRect.height * scaleY
        )
    }

    static func cropRectToDisplay(
        imagePixelCropRect: CGRect,
        imageSize: CGSize,
        displayRect: CGRect
    ) -> CGRect {
        let scaleX = displayRect.width / imageSize.width
        let scaleY = displayRect.height / imageSize.height
        return CGRect(
            x: displayRect.origin.x + imagePixelCropRect.origin.x * scaleX,
            y: displayRect.origin.y + imagePixelCropRect.origin.y * scaleY,
            width: imagePixelCropRect.width * scaleX,
            height: imagePixelCropRect.height * scaleY
        )
    }
}
