//
//  ImageFormatDetector.swift
//  Sahara
//
//  Created by 금가경 on 11/26/25.
//

import Foundation

struct ImageFormatDetector {
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
}
