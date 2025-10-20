//
//  MockMediaEditorCoordinator.swift
//  SaharaTests
//
//  Created by 금가경 on 10/20/25.
//

import UIKit
@testable import Sahara

final class MockMediaEditorCoordinator: MediaEditorCoordinatorProtocol {
    var presentStickerModalCalled = false
    var presentPhotoSelectionCalled = false
    var finishEditingCalled = false
    var cancelEditingCalled = false

    var lastPresentedViewModel: MediaEditorViewModel?
    var lastFinishedImage: UIImage?
    var lastStickerSelectedCompletion: ((KlipySticker) -> Void)?
    var lastPhotoSelectedCompletion: ((UIImage) -> Void)?

    func presentStickerModal(
        viewModel: MediaEditorViewModel,
        onStickerSelected: @escaping (KlipySticker) -> Void
    ) {
        presentStickerModalCalled = true
        lastPresentedViewModel = viewModel
        lastStickerSelectedCompletion = onStickerSelected
    }

    func presentPhotoSelection(
        onPhotoSelected: @escaping (UIImage) -> Void
    ) {
        presentPhotoSelectionCalled = true
        lastPhotoSelectedCompletion = onPhotoSelected
    }

    func finishEditing(with image: UIImage) {
        finishEditingCalled = true
        lastFinishedImage = image
    }

    func cancelEditing() {
        cancelEditingCalled = true
    }

    func reset() {
        presentStickerModalCalled = false
        presentPhotoSelectionCalled = false
        finishEditingCalled = false
        cancelEditingCalled = false
        lastPresentedViewModel = nil
        lastFinishedImage = nil
        lastStickerSelectedCompletion = nil
        lastPhotoSelectedCompletion = nil
    }
}
