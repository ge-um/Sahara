//
//  ImageFormatHelper.swift
//  Sahara
//
//  Created by 금가경 on 12/17/25.
//

import OSLog
import UIKit

final class ImageFormatHelper {
    static func detect(from data: Data) -> ImageSourceData.ImageFormat? {
        guard data.count >= 12 else { return nil }
        let bytes = [UInt8](data.prefix(12))

        if bytes.count >= 12,
           bytes[4] == 0x66, bytes[5] == 0x74, bytes[6] == 0x79, bytes[7] == 0x70,
           bytes[8] == 0x68, bytes[9] == 0x65, bytes[10] == 0x69 {
            return .heic
        }

        if bytes[0] == 0xFF, bytes[1] == 0xD8, bytes[2] == 0xFF {
            return .jpeg
        }

        if bytes[0] == 0x89, bytes[1] == 0x50, bytes[2] == 0x4E, bytes[3] == 0x47 {
            return .png
        }

        return nil
    }

    static func detectFromUTI(_ uti: String) -> ImageSourceData.ImageFormat? {
        switch uti {
        case "public.heic", "public.heif":
            return .heic
        case "public.jpeg", "public.jpg":
            return .jpeg
        case "public.png":
            return .png
        default:
            return nil
        }
    }

    struct ConversionResult {
        let editedImageData: Data
        let imageFormat: String
    }

    static func convertToFormat(
        editedImage: UIImage,
        targetFormat: ImageSourceData.ImageFormat?
    ) -> ConversionResult {
        let format = targetFormat ?? detectOptimalFormat(for: editedImage)
        let imageToConvert = removeUnnecessaryAlpha(from: editedImage, for: format)
        let editedData: Data

        switch format {
        case .heic:
            editedData = imageToConvert.heicData(compressionQuality: 1.0)
                         ?? imageToConvert.jpegData(compressionQuality: 1.0)!
        case .png:
            editedData = imageToConvert.pngData()!
        case .jpeg:
            editedData = imageToConvert.jpegData(compressionQuality: 1.0)!
        }

        return ConversionResult(
            editedImageData: editedData,
            imageFormat: format.rawValue
        )
    }

    private static func removeUnnecessaryAlpha(from image: UIImage, for format: ImageSourceData.ImageFormat) -> UIImage {
        guard format == .heic || format == .jpeg else {
            return image
        }

        guard let cgImage = image.cgImage else {
            return image
        }

        let alphaInfo = cgImage.alphaInfo
        let hasAlpha = !(alphaInfo == .none || alphaInfo == .noneSkipFirst || alphaInfo == .noneSkipLast)

        guard hasAlpha else {
            return image
        }

        let width = cgImage.width
        let height = cgImage.height
        let colorSpace = cgImage.colorSpace ?? CGColorSpaceCreateDeviceRGB()

        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        ) else {
            return image
        }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        guard let newCGImage = context.makeImage() else {
            return image
        }

        return UIImage(cgImage: newCGImage, scale: image.scale, orientation: image.imageOrientation)
    }

    private static func detectOptimalFormat(for image: UIImage) -> ImageSourceData.ImageFormat {
        let hasAlpha: Bool
        if let alphaInfo = image.cgImage?.alphaInfo {
            hasAlpha = !(alphaInfo == .none || alphaInfo == .noneSkipFirst || alphaInfo == .noneSkipLast)
        } else {
            hasAlpha = false
        }

        return hasAlpha ? .png : .heic
    }
}
