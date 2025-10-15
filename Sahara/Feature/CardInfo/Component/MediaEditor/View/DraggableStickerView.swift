//
//  DraggableStickerView.swift
//  Sahara
//
//  Created by 금가경 on 9/26/25.
//

import Kingfisher
import UIKit

final class DraggableStickerView: UIView, UIGestureRecognizerDelegate {
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    var onDragChanged: ((DraggableStickerView) -> Void)?
    var onDragEnded: ((DraggableStickerView) -> Void)?

    private var lastScale: CGFloat = 1.0
    private var lastRotation: CGFloat = 0.0

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureUI()
        setupGestures()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureUI() {
        addSubview(imageView)
        imageView.frame = bounds
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }

    private func setupGestures() {
        // Pan Gesture (드래그)
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        panGesture.delegate = self
        addGestureRecognizer(panGesture)

        // Pinch Gesture (확대/축소)
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        pinchGesture.delegate = self
        addGestureRecognizer(pinchGesture)

        // Rotation Gesture (회전)
        let rotationGesture = UIRotationGestureRecognizer(target: self, action: #selector(handleRotation(_:)))
        rotationGesture.delegate = self
        addGestureRecognizer(rotationGesture)

        isUserInteractionEnabled = true
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

    func configure(with sticker: KlipySticker) {
        // 고화질(hd 또는 md) 이미지를 사용
        var urlString: String?

        if let hd = sticker.file.hd {
            urlString = hd.webp?.url ?? hd.gif?.url
        } else if let md = sticker.file.md {
            urlString = md.webp?.url ?? md.gif?.url
        } else if let sm = sticker.file.sm {
            urlString = sm.webp?.url ?? sm.gif?.url
        } else if let xs = sticker.file.xs {
            urlString = xs.webp?.url ?? xs.gif?.url
        }

        if let urlString = urlString, let url = URL(string: urlString) {
            imageView.kf.setImage(with: url)
        }
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: superview)

        if let view = gesture.view {
            view.center = CGPoint(x: view.center.x + translation.x,
                                 y: view.center.y + translation.y)
        }

        gesture.setTranslation(.zero, in: superview)

        switch gesture.state {
        case .changed:
            onDragChanged?(self)
        case .ended, .cancelled:
            onDragEnded?(self)
        default:
            break
        }
    }

    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard let view = gesture.view else { return }

        switch gesture.state {
        case .began, .changed:
            let scale = gesture.scale
            view.transform = view.transform.scaledBy(x: scale, y: scale)
            gesture.scale = 1.0
        case .ended:
            lastScale = gesture.scale
        default:
            break
        }
    }

    @objc private func handleRotation(_ gesture: UIRotationGestureRecognizer) {
        guard let view = gesture.view else { return }

        switch gesture.state {
        case .began, .changed:
            view.transform = view.transform.rotated(by: gesture.rotation)
            gesture.rotation = 0
        case .ended:
            lastRotation = gesture.rotation
        default:
            break
        }
    }
}