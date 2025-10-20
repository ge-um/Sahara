//
//  MediaEditorCoordinator.swift
//  Sahara
//
//  Created by 금가경 on 10/20/25.
//

import UIKit

protocol MediaEditorCoordinatorDelegate: AnyObject {
    func didFinishEditing(with image: UIImage)
    func didCancelEditing()
}

final class MediaEditorCoordinator: Coordinator {
    var navigationController: UINavigationController?
    weak var delegate: MediaEditorCoordinatorDelegate?

    private let originalImage: UIImage

    init(navigationController: UINavigationController?, originalImage: UIImage) {
        self.navigationController = navigationController
        self.originalImage = originalImage
    }

    func start() {
        let viewModel = MediaEditorViewModel(originalImage: originalImage)
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
        mediaSelectionVC.onMediaSelected = { image, _, _ in
            onPhotoSelected(image)
        }

        let navController = UINavigationController(rootViewController: mediaSelectionVC)
        if let sheet = navController.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
        }
        currentVC.present(navController, animated: true)
    }

    func finishEditing(with image: UIImage) {
        delegate?.didFinishEditing(with: image)
    }

    func cancelEditing() {
        if let navController = navigationController {
            navController.dismiss(animated: true)
        }
        delegate?.didCancelEditing()
    }
}
