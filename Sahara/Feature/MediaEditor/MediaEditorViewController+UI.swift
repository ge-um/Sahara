//
//  MediaEditorViewController+UI.swift
//  Sahara
//
//  Created by 금가경 on 10/15/25.
//

import SnapKit
import UIKit

extension MediaEditorViewController {
    func setupCustomNavigationBar() {
        customNavigationBar.configure(title: NSLocalizedString("media_editor.title", comment: ""))
        customNavigationBar.hideLeftButton()

        view.addSubview(cancelButton)
        view.addSubview(doneButton)

        cancelButton.snp.makeConstraints { make in
            make.leading.equalTo(customNavigationBar.contentLeadingGuide.snp.trailing)
            make.centerY.equalTo(customNavigationBar)
            make.width.equalTo(48)
            make.height.equalTo(44)
        }

        doneButton.snp.makeConstraints { make in
            make.trailing.equalTo(customNavigationBar).inset(16)
            make.centerY.equalTo(customNavigationBar)
            make.width.greaterThanOrEqualTo(48)
            make.height.equalTo(44)
        }
    }

    func setupModeButtons() {
        let buttonConfigs: [(button: UIButton, imageName: String, titleKey: String)] = [
            (stickerModeButton, "sticker", "media_editor.sticker"),
            (drawingModeButton, "pencil", "media_editor.drawing"),
            (filterModeButton, "sliders", "media_editor.filter"),
            (photoModeButton, "image", "media_editor.photo"),
            (cropModeButton, "crop", "media_editor.crop")
        ]

        for config in buttonConfigs {
            let stack = UIStackView()
            stack.axis = .vertical
            stack.alignment = .center
            stack.spacing = 4
            stack.isUserInteractionEnabled = false

            let imageView = UIImageView()
            if let originalImage = UIImage(named: config.imageName) {
                imageView.image = originalImage.withRenderingMode(.alwaysTemplate)
            }
            imageView.contentMode = .scaleAspectFit
            imageView.tintColor = .black

            let label = UILabel()
            let text = NSLocalizedString(config.titleKey, comment: "")
            let attributedString = text.attributedString(
                font: FontSystem.galmuriMono(size: 12),
                letterSpacing: -6,
                color: .black
            )
            label.attributedText = attributedString
            label.textAlignment = .center

            stack.addArrangedSubview(imageView)
            stack.addArrangedSubview(label)

            imageView.snp.makeConstraints { make in
                make.width.height.equalTo(24)
            }

            config.button.addSubview(stack)
            stack.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }

            modeButtonStackView.addArrangedSubview(config.button)
        }
    }

    func configureUI() {
        view.applyGradient(.warm)

        view.addSubview(cropDimOverlay)
        view.addSubview(customNavigationBar)
        view.addSubview(photoImageView)
        view.addSubview(stickerContainerView)
        view.addSubview(canvasView)
        view.addSubview(toolBarContainer)
        view.addSubview(filterContainerView)
        filterContainerView.addSubview(filterCollectionView)
        view.addSubview(trashIconView)
        view.addSubview(leftStarImageView)
        view.addSubview(rightStarImageView)
        view.addSubview(cropOverlayView)
        view.addSubview(cropApplyButton)
        view.addSubview(cropCancelButton)
        view.addSubview(drawingToolStrip)
        view.addSubview(undoButton)
        view.addSubview(redoButton)

        toolBarContainer.addSubview(toolBarScrollView)
        toolBarScrollView.addSubview(modeButtonStackView)

        toolBarContainer.applyGradient(.tabBar)

        customNavigationBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.horizontalEdges.equalToSuperview()
            make.height.equalTo(54)
        }

        toolBarContainer.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(88)
        }

        toolBarScrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        modeButtonStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 16, left: 20, bottom: 8, right: 20))
            make.height.equalTo(54)
        }

        photoImageView.snp.makeConstraints { make in
            make.top.equalTo(customNavigationBar.snp.bottom).offset(20)
            make.horizontalEdges.equalToSuperview().inset(40)
            make.bottom.equalTo(drawingToolStrip.snp.top).offset(-20)
        }


        stickerContainerView.snp.makeConstraints { make in
            make.edges.equalTo(photoImageView)
        }

        canvasView.snp.makeConstraints { make in
            make.edges.equalTo(photoImageView)
        }

        filterContainerView.applyGradient(.tabBar)
        filterContainerView.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview().inset(16)
            make.bottom.equalTo(toolBarContainer.snp.top).offset(-28)
            make.height.equalTo(144)
        }
        filterCollectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        trashIconView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(toolBarContainer.snp.top).offset(-28)
            make.width.height.equalTo(40)
        }


        cropApplyButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(20)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-10)
            make.width.equalTo(100)
            make.height.equalTo(50)
        }

        cropCancelButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(20)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-10)
            make.width.equalTo(100)
            make.height.equalTo(50)
        }

        cropDimOverlay.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        drawingToolStrip.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview().inset(16)
            make.bottom.equalTo(toolBarContainer.snp.top).offset(-28)
            make.height.equalTo(144)
        }
        drawingToolStrip.isHidden = true

        undoButton.snp.makeConstraints { make in
            make.trailing.equalTo(view.snp.centerX).offset(-4)
            make.bottom.equalTo(photoImageView.snp.top).offset(-8)
            make.width.height.equalTo(36)
        }

        redoButton.snp.makeConstraints { make in
            make.leading.equalTo(view.snp.centerX).offset(4)
            make.bottom.equalTo(photoImageView.snp.top).offset(-8)
            make.width.height.equalTo(36)
        }
    }

    func updateStarPositions() {
        guard let image = photoImageView.image else { return }

        let imageRect = ImageCoordinateSpace.displayRect(
            imageSize: image.size,
            in: photoImageView.bounds.size
        )

        let imageFrameInView = CGRect(
            x: photoImageView.frame.origin.x + imageRect.origin.x,
            y: photoImageView.frame.origin.y + imageRect.origin.y,
            width: imageRect.width,
            height: imageRect.height
        )

        leftStarImageView.snp.remakeConstraints { make in
            make.centerX.equalTo(view).offset(imageFrameInView.minX - view.bounds.width / 2)
            make.centerY.equalTo(view).offset(imageFrameInView.minY - view.bounds.height / 2)
            make.width.height.equalTo(32)
        }

        rightStarImageView.snp.remakeConstraints { make in
            make.centerX.equalTo(view).offset(imageFrameInView.maxX - view.bounds.width / 2)
            make.centerY.equalTo(view).offset(imageFrameInView.minY - view.bounds.height / 2)
            make.width.height.equalTo(32)
        }
    }
}
