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
                sourceFormat: sourceFormat
            )
        }
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
        sourceFormat: ImageSourceData.ImageFormat?
    ) -> Observable<PreparedImageData> {
        let result = ImageFormatHelper.convertToFormat(
            editedImage: baseImage,
            targetFormat: sourceFormat
        )
        Logger.imageMetadata.info("Prepared image: stickers=0, format=\(result.imageFormat)")
        return Observable.just(PreparedImageData(
            editedImageData: result.editedImageData,
            imageFormat: result.imageFormat
        ))
    }
}
