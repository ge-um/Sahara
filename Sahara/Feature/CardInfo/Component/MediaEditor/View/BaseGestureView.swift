//
//  BaseGestureView.swift
//  Sahara
//
//  Created by 금가경 on 10/15/25.
//

import UIKit

class BaseGestureView: UIView {
    var onDragChanged: ((BaseGestureView) -> Void)?
    var onDragEnded: ((BaseGestureView) -> Void)?
    var onTapped: ((BaseGestureView) -> Void)?

    var isSelected: Bool = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        onTapped?(self)
    }

    func applyPanTranslation(_ translation: CGPoint) {
        center = CGPoint(x: center.x + translation.x, y: center.y + translation.y)
    }

    func applyPinchScale(_ scale: CGFloat) {
        transform = transform.scaledBy(x: scale, y: scale)
    }

    func applyRotation(_ rotation: CGFloat) {
        transform = transform.rotated(by: rotation)
    }
}
