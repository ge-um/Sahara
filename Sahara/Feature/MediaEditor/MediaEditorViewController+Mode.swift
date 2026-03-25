//
//  MediaEditorViewController+Mode.swift
//  Sahara
//
//  Created by 금가경 on 10/15/25.
//

import PhotosUI
import UIKit

extension MediaEditorViewController {
    func updateEditMode(mode: EditMode?) {
        filterContainerView.isHidden = true
        drawingToolStrip.isHidden = true
        canvasView.isUserInteractionEnabled = false
        photoImageView.isUserInteractionEnabled = false
        stickerContainerView.isUserInteractionEnabled = true
        cropOverlayView.isHidden = true
        cropApplyButton.isHidden = true
        cropCancelButton.isHidden = true
        cropDimOverlay.isHidden = true
        customNavigationBar.isHidden = false
        toolBarContainer.isHidden = false
        doneButton.isHidden = false
        leftStarImageView.isHidden = false
        rightStarImageView.isHidden = false
        cancelButton.isEnabled = true
        undoButton.isHidden = true
        redoButton.isHidden = true

        guard let mode = mode else {
            doneButton.isHidden = false
            doneButton.isEnabled = true
            doneButton.alpha = 1.0
            return
        }

        switch mode {
        case .sticker:
            break
        case .drawing:
            canvasView.isUserInteractionEnabled = true
            canvasView.becomeFirstResponder()
            drawingToolStrip.alpha = 0
            drawingToolStrip.isHidden = false
            UIView.animate(withDuration: 0.25) {
                self.drawingToolStrip.alpha = 1
            }
            updateUndoRedoButtons()
        case .filter:
            filterContainerView.isHidden = false
            filterCollectionView.reloadData()
        case .photo:
            presentPhotoSelectionModal()
        case .crop:
            leftStarImageView.isHidden = true
            rightStarImageView.isHidden = true
            cropDimOverlay.isHidden = false
            customNavigationBar.isHidden = true
            toolBarContainer.isHidden = true
            cancelButton.isHidden = true
            doneButton.isHidden = true

            cropOverlayView.isHidden = false
            cropApplyButton.isHidden = false
            cropCancelButton.isHidden = false

            guard let uncropped = cachedUncroppedOriginalImage else { return }
            photoImageView.image = uncropped

            view.layoutIfNeeded()
            setupCropOverlay()
        }
    }

    func updateModeButtons(currentMode: EditMode?) {
        let buttons = [stickerModeButton, drawingModeButton, filterModeButton, photoModeButton, cropModeButton]
        let modes: [EditMode?] = [.sticker, .drawing, .filter, .photo, .crop]

        for (button, mode) in zip(buttons, modes) {
            if mode == currentMode {
                button.alpha = 1.0
            } else {
                button.alpha = 0.5
            }
        }
    }

    func presentStickerModal() {
        coordinator?.presentStickerModal(viewModel: viewModel) { [weak self] sticker in
            self?.addStickerToPhoto(sticker)
        }
    }

    func presentPhotoSelectionModal() {
        coordinator?.presentPhotoSelection { [weak self] image in
            self?.addPhotoToCanvas(image)
            self?.currentMode.accept(nil)
        }
    }
}

extension MediaEditorViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)

        guard let itemProvider = results.first?.itemProvider else { return }

        if itemProvider.canLoadObject(ofClass: UIImage.self) {
            itemProvider.loadObject(ofClass: UIImage.self) { [weak self] image, _ in
                DispatchQueue.main.async {
                    guard let image = image as? UIImage else { return }
                    self?.photoSelectedRelay.accept(image)
                }
            }
        }
    }
}
