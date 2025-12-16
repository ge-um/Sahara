//
//  ImageFormatHelper.swift
//  Sahara
//
//  Created by 금가경 on 12/17/25.
//

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
        let originalImageData: Data
        let imageFormat: String
    }

    static func convertImages(
        editedImage: UIImage,
        originalImage: UIImage,
        sourceFormat: ImageSourceData.ImageFormat?
    ) -> ConversionResult {
        if let format = sourceFormat {
            switch format {
            case .heic:
                return ConversionResult(
                    editedImageData: editedImage.heicData(compressionQuality: 1.0) ?? editedImage.jpegData(compressionQuality: 1.0)!,
                    originalImageData: originalImage.heicData(compressionQuality: 1.0) ?? originalImage.jpegData(compressionQuality: 1.0)!,
                    imageFormat: "heic"
                )
            case .png:
                return ConversionResult(
                    editedImageData: editedImage.pngData()!,
                    originalImageData: originalImage.pngData()!,
                    imageFormat: "png"
                )
            case .jpeg:
                return ConversionResult(
                    editedImageData: editedImage.jpegData(compressionQuality: 1.0)!,
                    originalImageData: originalImage.jpegData(compressionQuality: 1.0)!,
                    imageFormat: "jpeg"
                )
            }
        } else {
            let hasAlpha: Bool
            if let alphaInfo = editedImage.cgImage?.alphaInfo {
                hasAlpha = !(alphaInfo == .none || alphaInfo == .noneSkipFirst || alphaInfo == .noneSkipLast)
            } else {
                hasAlpha = false
            }

            if hasAlpha {
                return ConversionResult(
                    editedImageData: editedImage.pngData()!,
                    originalImageData: originalImage.pngData()!,
                    imageFormat: "png"
                )
            } else {
                return ConversionResult(
                    editedImageData: editedImage.jpegData(compressionQuality: 1.0)!,
                    originalImageData: originalImage.jpegData(compressionQuality: 1.0)!,
                    imageFormat: "jpeg"
                )
            }
        }
    }
}
