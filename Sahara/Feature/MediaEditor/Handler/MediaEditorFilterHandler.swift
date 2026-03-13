//
//  MediaEditorFilterHandler.swift
//  Sahara
//
//  Created by 금가경 on 10/15/25.
//

import CoreImage
import UIKit

final class MediaEditorFilterHandler {
    let context = CIContext()

    static let filters: [(name: String, filterName: String?)] = [
        (NSLocalizedString("filter.original", comment: ""), nil),
        (NSLocalizedString("filter.noir", comment: ""), "CIPhotoEffectNoir"),
        (NSLocalizedString("filter.sepia", comment: ""), "CISepiaTone"),
        (NSLocalizedString("filter.instant", comment: ""), "CIPhotoEffectInstant"),
        (NSLocalizedString("filter.chrome", comment: ""), "CIPhotoEffectChrome"),
        (NSLocalizedString("filter.fade", comment: ""), "CIPhotoEffectFade"),
        (NSLocalizedString("filter.mono", comment: ""), "CIPhotoEffectMono"),
        (NSLocalizedString("filter.process", comment: ""), "CIPhotoEffectProcess"),
        (NSLocalizedString("filter.transfer", comment: ""), "CIPhotoEffectTransfer"),
        (NSLocalizedString("filter.tonal", comment: ""), "CIPhotoEffectTonal")
    ]

    func applyFilter(at index: Int, to image: UIImage) -> UIImage? {
        guard index < Self.filters.count else { return image }

        let filterItem = Self.filters[index]

        if index == 0 {
            return image
        }

        guard let filterName = filterItem.filterName,
              let filter = CIFilter(name: filterName) else {
            return image
        }

        guard let ciImage = CIImage(image: image) else { return nil }

        filter.setValue(ciImage, forKey: kCIInputImageKey)

        guard let outputImage = filter.outputImage,
              let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            return nil
        }

        return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
    }
}
