//
//  MediaEditorCoordinator.swift
//  Sahara
//
//  Created by 금가경 on 10/20/25.
//

import UIKit

protocol MediaEditorCoordinatorDelegate: AnyObject {
    func didFinishEditing(with image: UIImage, stickers: [StickerDTO], wasEdited: Bool, filterIndex: Int?, cropMetadata: CropMetadata?, rotationAngle: Double)
    func didCancelEditing()
}

final class MediaEditorCoordinator: Coordinator, MediaEditorCoordinatorProtocol {
    var navigationController: UINavigationController?
    weak var delegate: MediaEditorCoordinatorDelegate?

    private let imageSource: ImageSourceData

    init(navigationController: UINavigationController?, imageSource: ImageSourceData) {
        self.navigationController = navigationController
        self.imageSource = imageSource
    }

    func start() {
        let viewModel = MediaEditorViewModel(imageSource: imageSource)
        let editorVC = MediaEditorViewController(viewModel: viewModel)
        editorVC.coordinator = self

        navigationController?.pushViewController(editorVC, animated: true)
    }

    func presentStickerModal(
        viewModel: MediaEditorViewModel,
        onStickerSelected: @escaping (KlipySticker) -> Void
    ) {
        guard let currentVC = navigationController?.topViewController else { return }

        let stickerModalVC = StickerModalViewController(viewModel: viewModel)
        stickerModalVC.onStickerSelected = onStickerSelected

        let navController = UINavigationController(rootViewController: stickerModalVC)
        if let sheet = navController.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
        }
        currentVC.present(navController, animated: true)
    }

    func presentPhotoSelection(onPhotoSelected: @escaping (UIImage) -> Void) {
        guard let currentVC = navigationController?.topViewController else { return }

        let mediaSelectionVC = MediaSelectionViewController()
        mediaSelectionVC.onMediaSelected = { imageSource, _, _ in
            onPhotoSelected(imageSource.image)
        }

        let navController = UINavigationController(rootViewController: mediaSelectionVC)
        if let sheet = navController.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
        }
        currentVC.present(navController, animated: true)
    }

    func finishEditing(with image: UIImage, stickers: [StickerDTO], wasEdited: Bool, filterIndex: Int?, cropMetadata: CropMetadata?, rotationAngle: Double) {
        delegate?.didFinishEditing(with: image, stickers: stickers, wasEdited: wasEdited, filterIndex: filterIndex, cropMetadata: cropMetadata, rotationAngle: rotationAngle)
    }

    func cancelEditing() {
        if let navController = navigationController {
            navController.dismiss(animated: true)
        }
        delegate?.didCancelEditing()
    }
}
