//
//  MediaEditorImageStateHandler.swift
//  Sahara
//
//  Created by 금가경 on 10/20/25.
//

import RxCocoa
import RxSwift
import UIKit

final class MediaEditorImageStateHandler {
    private let originalImageRelay: BehaviorRelay<UIImage>
    private let currentEditingImageRelay: BehaviorRelay<UIImage>
    private let croppedImageRelay: BehaviorRelay<UIImage?>
    private let uncroppedOriginalImageRelay: BehaviorRelay<UIImage>

    init(originalImage: UIImage) {
        self.originalImageRelay = BehaviorRelay(value: originalImage)
        self.currentEditingImageRelay = BehaviorRelay(value: originalImage)
        self.croppedImageRelay = BehaviorRelay(value: nil)
        self.uncroppedOriginalImageRelay = BehaviorRelay(value: originalImage)
    }

    var originalImage: Driver<UIImage> {
        originalImageRelay.asDriver()
    }

    var currentEditingImage: Driver<UIImage> {
        currentEditingImageRelay.asDriver()
    }

    var croppedImage: Driver<UIImage?> {
        croppedImageRelay.asDriver()
    }

    var uncroppedOriginalImage: Driver<UIImage> {
        uncroppedOriginalImageRelay.asDriver()
    }

    func updateCurrentEditingImage(_ image: UIImage) {
        currentEditingImageRelay.accept(image)
    }

    func applyCrop(_ croppedImage: UIImage) {
        croppedImageRelay.accept(croppedImage)
        currentEditingImageRelay.accept(croppedImage)
        originalImageRelay.accept(croppedImage)
    }

    func applyFilter(_ filteredImage: UIImage) {
        currentEditingImageRelay.accept(filteredImage)
    }

    func getCurrentImage() -> UIImage {
        currentEditingImageRelay.value
    }

    func getCroppedOrOriginalImage() -> UIImage {
        croppedImageRelay.value ?? originalImageRelay.value
    }
}
