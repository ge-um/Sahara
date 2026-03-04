//
//  ImagePrepareService.swift
//  Sahara
//
//  Created by 금가경 on 2/28/26.
//

import OSLog
import RxSwift
import UIKit

struct PreparedImageData {
    let editedImageData: Data
    let imageFormat: String
}

protocol ImagePrepareServiceProtocol {
    func prepareForSave(
        baseImage: UIImage,
        metadata: ImageSourceData
    ) -> Observable<PreparedImageData>
}

final class ImagePrepareService: ImagePrepareServiceProtocol {

    func prepareForSave(
        baseImage: UIImage,
        metadata: ImageSourceData
    ) -> Observable<PreparedImageData> {
        let realmDataLimit = 15 * 1_024 * 1_024  // 15 MB (Realm 16 MB 상한 마진)
        if let originalData = metadata.originalData, !metadata.hasEdits,
           originalData.count < realmDataLimit {
            return bypassWithOriginalData(originalData, format: metadata.format)
        }

        let stickers = metadata.stickers
        let sourceFormat = metadata.format
        let editorViewSize = metadata.editorViewSize

        if !stickers.isEmpty {
            return compositeThenConvert(
                baseImage: baseImage,
                stickers: stickers,
                sourceFormat: sourceFormat,
                editorViewSize: editorViewSize
            )
        } else {
            return convertOnly(
                baseImage: baseImage,
                sourceFormat: sourceFormat,
                originalData: metadata.originalData
            )
        }
    }

    private func bypassWithOriginalData(
        _ originalData: Data,
        format: ImageSourceData.ImageFormat?
    ) -> Observable<PreparedImageData> {
        let formatString = format?.rawValue ?? "heic"
        Logger.imageMetadata.info("Bypassed re-encoding: original bytes (\(originalData.count / 1024)KB, format=\(formatString))")
        return Observable.just(PreparedImageData(
            editedImageData: originalData,
            imageFormat: formatString
        ))
    }

    private func compositeThenConvert(
        baseImage: UIImage,
        stickers: [StickerDTO],
        sourceFormat: ImageSourceData.ImageFormat?,
        editorViewSize: CGSize?
    ) -> Observable<PreparedImageData> {
        return Observable.create { observer in
            MediaEditorImageHandler.compositeStickersOnImage(
                baseImage,
                stickers: stickers,
                editorViewSize: editorViewSize
            ) { compositedImage, _ in
                let result = ImageFormatHelper.convertToFormat(
                    editedImage: compositedImage,
                    targetFormat: sourceFormat
                )
                Logger.imageMetadata.info("Prepared image: stickers=\(stickers.count), format=\(result.imageFormat)")
                observer.onNext(PreparedImageData(
                    editedImageData: result.editedImageData,
                    imageFormat: result.imageFormat
                ))
                observer.onCompleted()
            }
            return Disposables.create()
        }
    }

    private func convertOnly(
        baseImage: UIImage,
        sourceFormat: ImageSourceData.ImageFormat?,
        originalData: Data?
    ) -> Observable<PreparedImageData> {
        let result = ImageFormatHelper.convertToFormat(
            editedImage: baseImage,
            targetFormat: sourceFormat
        )

        logQualityComparison(originalData: originalData, reEncodedData: result.editedImageData, format: result.imageFormat)

        Logger.imageMetadata.info("Prepared image: stickers=0, format=\(result.imageFormat)")
        return Observable.just(PreparedImageData(
            editedImageData: result.editedImageData,
            imageFormat: result.imageFormat
        ))
    }

    private func logQualityComparison(originalData: Data?, reEncodedData: Data, format: String) {
        guard let originalData = originalData else {
            Logger.imageMetadata.info("[Quality] No original data to compare (camera source)")
            return
        }

        let originalSize = originalData.count
        let reEncodedSize = reEncodedData.count
        let ratio = Double(reEncodedSize) / Double(originalSize) * 100
        let diff = reEncodedSize - originalSize

        Logger.imageMetadata.notice("[Quality] Original: \(originalSize) bytes (\(originalSize / 1024)KB)")
        Logger.imageMetadata.notice("[Quality] Re-encoded: \(reEncodedSize) bytes (\(reEncodedSize / 1024)KB)")
        Logger.imageMetadata.notice("[Quality] Ratio: \(String(format: "%.1f", ratio))%, diff=\(diff > 0 ? "+" : "")\(diff / 1024)KB, format=\(format)")

        let originalDimensions = ImageDownsampler.imageSize(from: originalData)
        let reEncodedDimensions = ImageDownsampler.imageSize(from: reEncodedData)

        if let origDim = originalDimensions, let reEncDim = reEncodedDimensions {
            Logger.imageMetadata.notice("[Quality] Original dimensions: \(Int(origDim.width))x\(Int(origDim.height))")
            Logger.imageMetadata.notice("[Quality] Re-encoded dimensions: \(Int(reEncDim.width))x\(Int(reEncDim.height))")

            let origPixels = Int(origDim.width) * Int(origDim.height)
            let reEncPixels = Int(reEncDim.width) * Int(reEncDim.height)
            if origPixels != reEncPixels {
                Logger.imageMetadata.error("[Quality] Resolution changed! (\(origPixels) → \(reEncPixels) pixels)")
            }
        }
    }
}
