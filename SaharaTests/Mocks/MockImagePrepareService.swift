//
//  MockImagePrepareService.swift
//  SaharaTests
//
//  Created by 금가경 on 2/28/26.
//

import RxSwift
import UIKit
@testable import Sahara

final class MockImagePrepareService: ImagePrepareServiceProtocol {
    var prepareForSaveCalled = false
    var lastBaseImage: UIImage?
    var lastMetadata: ImageSourceData?

    func prepareForSave(baseImage: UIImage, metadata: ImageSourceData) -> Observable<PreparedImageData> {
        prepareForSaveCalled = true
        lastBaseImage = baseImage
        lastMetadata = metadata

        let data = baseImage.jpegData(compressionQuality: 0.8) ?? Data()
        return Observable.just(PreparedImageData(
            editedImageData: data,
            imageFormat: "jpeg"
        ))
    }
}
