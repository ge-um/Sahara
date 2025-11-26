//
//  MediaEditorCoordinatorProtocol.swift
//  Sahara
//
//  Created by 금가경 on 10/20/25.
//

import UIKit

protocol MediaEditorCoordinatorProtocol: AnyObject {
    func presentStickerModal(
        viewModel: MediaEditorViewModel,
        onStickerSelected: @escaping (KlipySticker) -> Void
    )

    func presentPhotoSelection(
        onPhotoSelected: @escaping (UIImage) -> Void
    )

    func finishEditing(with image: UIImage, stickers: [StickerDTO], wasEdited: Bool)
    func cancelEditing()
}
