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
        filterCollectionView.isHidden = true
        canvasView.isUserInteractionEnabled = false
        toolPicker.setVisible(false, forFirstResponder: canvasView)
        photoImageView.isUserInteractionEnabled = false
        stickerContainerView.isUserInteractionEnabled = true
        cropOverlayView.isHidden = true
        cropApplyButton.isHidden = true
        cropCancelButton.isHidden = true
        cropDimOverlay.isHidden = true
        toolBarContainer.isHidden = false
        doneButton.isHidden = false
        leftStarImageView.isHidden = false
        rightStarImageView.isHidden = false
        cancelButton.isEnabled = true

        photoImageView.snp.remakeConstraints { make in
            make.top.equalTo(customNavigationBar.snp.bottom).offset(40)
            make.horizontalEdges.equalToSuperview().inset(40)
            make.bottom.equalTo(toolBarContainer.snp.top).offset(-48)
        }

        stickerContainerView.snp.remakeConstraints { make in
            make.edges.equalTo(photoImageView)
        }

        canvasView.snp.remakeConstraints { make in
            make.edges.equalTo(photoImageView)
        }

        toolBarContainer.snp.remakeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(88)
        }

        UIView.animate(withDuration: 0.3, animations: {
            self.view.layoutIfNeeded()
        }, completion: { _ in
            self.adjustStickerPositions()
        })

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

            toolBarContainer.snp.remakeConstraints { make in
                make.leading.trailing.equalToSuperview()
                make.height.equalTo(88)
                make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-75)
            }

            UIView.animate(withDuration: 0.3, animations: {
                self.view.layoutIfNeeded()
            }, completion: { _ in
                self.adjustStickerPositions()
            })

            toolPicker.setVisible(true, forFirstResponder: canvasView)
        case .filter:
            photoImageView.snp.remakeConstraints { make in
                make.top.equalTo(customNavigationBar.snp.bottom).offset(40)
                make.horizontalEdges.equalToSuperview().inset(40)
                make.bottom.equalTo(filterCollectionView.snp.top).offset(-16)
            }

            filterCollectionView.isHidden = false

            UIView.animate(withDuration: 0.3, animations: {
                self.view.layoutIfNeeded()
            }, completion: { _ in
                self.adjustStickerPositions()
                self.filterCollectionView.reloadData()
                self.filterCollectionView.layoutIfNeeded()
            })
        case .photo:
            presentPhotoSelectionModal()
        case .crop:
            leftStarImageView.isHidden = true
            rightStarImageView.isHidden = true
            cropDimOverlay.isHidden = false
            cancelButton.isEnabled = false
            doneButton.alpha = 0.5
            doneButton.isEnabled = false

            cropApplyButton.snp.remakeConstraints { make in
                make.trailing.equalToSuperview().inset(20)
                make.bottom.equalTo(toolBarContainer.snp.top).offset(-28)
                make.width.greaterThanOrEqualTo(80)
                make.height.equalTo(44)
            }

            cropCancelButton.snp.remakeConstraints { make in
                make.leading.equalToSuperview().inset(20)
                make.bottom.equalTo(toolBarContainer.snp.top).offset(-28)
                make.width.greaterThanOrEqualTo(80)
                make.height.equalTo(44)
            }

            photoImageView.snp.remakeConstraints { make in
                make.top.equalTo(customNavigationBar.snp.bottom).offset(20)
                make.horizontalEdges.equalToSuperview().inset(20)
                make.bottom.equalTo(cropApplyButton.snp.top).offset(-20)
            }

            cropOverlayView.isHidden = false
            cropApplyButton.isHidden = false
            cropCancelButton.isHidden = false
            doneButton.isHidden = false

            guard let uncropped = uncropedOriginalImage else { return }
            photoImageView.image = uncropped

            UIView.animate(withDuration: 0.3, animations: {
                self.view.layoutIfNeeded()
            }, completion: { _ in
                self.adjustStickerPositions()
                self.setupCropOverlay()
            })
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
        let stickerModalVC = StickerModalViewController(viewModel: viewModel)
        stickerModalVC.onStickerSelected = { [weak self] sticker in
            self?.addStickerToPhoto(sticker)
        }

        let navController = UINavigationController(rootViewController: stickerModalVC)
        if let sheet = navController.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
        }
        present(navController, animated: true)
    }

    func presentPhotoSelectionModal() {
        let mediaSelectionVC = MediaSelectionViewController()
        mediaSelectionVC.onMediaSelected = { [weak self] image, _, _ in
            self?.addPhotoToCanvas(image)
            self?.currentMode.accept(nil)
        }
        let navController = UINavigationController(rootViewController: mediaSelectionVC)
        if let sheet = navController.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
        }
        present(navController, animated: true)
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
