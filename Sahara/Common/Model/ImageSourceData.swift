//
//  ImageSourceData.swift
//  Sahara
//
//  Created by 금가경 on 11/26/25.
//

import UIKit

struct ImageSourceData {
    let image: UIImage
    let originalData: Data?
    let format: ImageFormat?

    enum ImageFormat: String {
        case heic
        case jpeg
        case png

        var mimeType: String {
            switch self {
            case .heic:
                return "image/heic"
            case .jpeg:
                return "image/jpeg"
            case .png:
                return "image/png"
            }
        }

        var fileExtension: String {
            return rawValue
        }
    }

    init(image: UIImage, originalData: Data? = nil, format: ImageFormat? = nil) {
        self.image = image
        self.originalData = originalData
        self.format = format
    }
}
