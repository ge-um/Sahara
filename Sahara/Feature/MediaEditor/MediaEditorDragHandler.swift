//
//  MediaEditorDragHandler.swift
//  Sahara
//
//  Created by 금가경 on 10/1/25.
//

import UIKit

final class MediaEditorDragHandler {
    private let trashIconView: UIImageView
    private weak var parentView: UIView?

    init(trashIconView: UIImageView, parentView: UIView) {
        self.trashIconView = trashIconView
        self.parentView = parentView
    }

    func handleDragChanged(view: UIView) {
        guard let parentView = parentView else { return }

        let convertedPoint = parentView.convert(view.center, from: view.superview)
        let trashCenter = CGPoint(x: trashIconView.frame.midX, y: trashIconView.frame.midY)
        let distance = hypot(convertedPoint.x - trashCenter.x, convertedPoint.y - trashCenter.y)

        if distance < 150 {
            if trashIconView.isHidden {
                trashIconView.isHidden = false
            }
            let scale = max(1.0, 1.5 - (distance / 150))
            UIView.animate(withDuration: 0.1) {
                self.trashIconView.transform = CGAffineTransform(scaleX: scale, y: scale)
            }
        } else {
            UIView.animate(withDuration: 0.1) {
                self.trashIconView.transform = .identity
            }
        }
    }

    func handleDragEnded<T: UIView>(view: UIView, in array: inout [T]) -> Bool {
        guard let parentView = parentView else { return false }

        hideTrashIcon()

        let convertedPoint = parentView.convert(view.center, from: view.superview)
        let trashFrame = trashIconView.frame.insetBy(dx: -20, dy: -20)

        if trashFrame.contains(convertedPoint) {
            if let index = array.firstIndex(where: { $0 === view }) {
                array.remove(at: index)
            }

            UIView.animate(withDuration: 0.3, animations: {
                view.alpha = 0
                view.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
            }) { _ in
                view.removeFromSuperview()
            }

            return true
        }

        return false
    }

    func hideTrashIcon() {
        UIView.animate(withDuration: 0.2) {
            self.trashIconView.transform = .identity
        } completion: { _ in
            self.trashIconView.isHidden = true
        }
    }
}
