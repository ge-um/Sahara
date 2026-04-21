//
//  ImageOrientationTests.swift
//  SaharaTests
//
//  Created by 금가경 on 2/28/26.
//

import ImageIO
import XCTest
@testable import Sahara

final class ImageOrientationTests: XCTestCase {

    private func createImageWithOrientation(_ orientation: UIImage.Orientation, size: CGSize = CGSize(width: 100, height: 200)) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let baseImage = renderer.image { context in
            UIColor.red.setFill()
            context.fill(CGRect(x: 0, y: 0, width: size.width / 2, height: size.height / 2))
            UIColor.blue.setFill()
            context.fill(CGRect(x: size.width / 2, y: size.height / 2, width: size.width / 2, height: size.height / 2))
        }
        guard let cgImage = baseImage.cgImage else { return baseImage }
        return UIImage(cgImage: cgImage, scale: 1.0, orientation: orientation)
    }

    func test_normalizedOrientation_upReturnsIdentical() {
        let image = createImageWithOrientation(.up)
        let result = image.normalizedOrientation()
        XCTAssertEqual(result.imageOrientation, .up)
        XCTAssertEqual(result.size, image.size)
    }

    func test_normalizedOrientation_rightNormalizesToUp() {
        let image = createImageWithOrientation(.right, size: CGSize(width: 200, height: 100))
        let result = image.normalizedOrientation()
        XCTAssertEqual(result.imageOrientation, .up)
        XCTAssertEqual(result.size.width, image.size.width, accuracy: 1.0)
        XCTAssertEqual(result.size.height, image.size.height, accuracy: 1.0)
    }

    func test_normalizedOrientation_leftNormalizesToUp() {
        let image = createImageWithOrientation(.left, size: CGSize(width: 200, height: 100))
        let result = image.normalizedOrientation()
        XCTAssertEqual(result.imageOrientation, .up)
    }

    func test_normalizedOrientation_downNormalizesToUp() {
        let image = createImageWithOrientation(.down)
        let result = image.normalizedOrientation()
        XCTAssertEqual(result.imageOrientation, .up)
    }

    func test_heicData_rightOrientationEmbedsExif() {
        let image = createImageWithOrientation(.right, size: CGSize(width: 200, height: 100))
        let data = image.heicData(compressionQuality: 1.0)
        XCTAssertNotNil(data)

        guard let data = data,
              let source = CGImageSourceCreateWithData(data as CFData, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] else {
            XCTFail("Could not read image source properties")
            return
        }

        let orientation = properties[kCGImagePropertyOrientation] as? UInt32
        XCTAssertEqual(orientation, CGImagePropertyOrientation.right.rawValue)
    }

    func test_convertToFormat_heicWithRightOrientation_producesCorrectPixels() {
        let image = createImageWithOrientation(.right, size: CGSize(width: 100, height: 200))
        let result = ImageFormatConverter.convertToFormat(editedImage: image, targetFormat: .heic)

        guard let reloaded = UIImage(data: result.editedImageData) else {
            XCTFail("Could not reload HEIC data as UIImage")
            return
        }

        XCTAssertEqual(reloaded.size.width, image.size.width, accuracy: 1.0)
        XCTAssertEqual(reloaded.size.height, image.size.height, accuracy: 1.0)
    }

    func test_convertToFormat_pngWithRightOrientation_producesCorrectPixels() {
        let image = createImageWithOrientation(.right, size: CGSize(width: 100, height: 200))
        let result = ImageFormatConverter.convertToFormat(editedImage: image, targetFormat: .png)

        guard let reloaded = UIImage(data: result.editedImageData) else {
            XCTFail("Could not reload PNG data as UIImage")
            return
        }

        XCTAssertEqual(reloaded.size.width, image.size.width, accuracy: 1.0)
        XCTAssertEqual(reloaded.size.height, image.size.height, accuracy: 1.0)
    }

    func test_convertToFormat_jpegWithRightOrientation_producesCorrectPixels() {
        let image = createImageWithOrientation(.right, size: CGSize(width: 100, height: 200))
        let result = ImageFormatConverter.convertToFormat(editedImage: image, targetFormat: .jpeg)

        guard let reloaded = UIImage(data: result.editedImageData) else {
            XCTFail("Could not reload JPEG data as UIImage")
            return
        }

        XCTAssertEqual(reloaded.size.width, image.size.width, accuracy: 1.0)
        XCTAssertEqual(reloaded.size.height, image.size.height, accuracy: 1.0)
    }

    func test_downsample_afterConvertToFormat_preservesOrientation() {
        let image = createImageWithOrientation(.right, size: CGSize(width: 200, height: 400))
        let result = ImageFormatConverter.convertToFormat(editedImage: image, targetFormat: .heic)

        guard let downsampled = ImageDownsampler.downsample(data: result.editedImageData, maxDimension: 200) else {
            XCTFail("Downsample returned nil")
            return
        }

        XCTAssertGreaterThan(downsampled.size.width, downsampled.size.height)
    }
}
