//
//  CropOverlayView.swift
//  Sahara
//
//  Created by 금가경 on 9/26/25.
//

import UIKit

final class CropOverlayView: UIView {
    private let cropBoxView: UIView = {
        let view = UIView()
        view.layer.borderColor = UIColor.white.cgColor
        view.layer.borderWidth = 2
        view.backgroundColor = .clear
        return view
    }()

    private let dimView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        view.isUserInteractionEnabled = false
        return view
    }()

    private let topLeftHandle = CropHandleView()
    private let topRightHandle = CropHandleView()
    private let bottomLeftHandle = CropHandleView()
    private let bottomRightHandle = CropHandleView()

    private var initialCropRect: CGRect = .zero
    private var currentHandle: CropHandleView?

    var cropRect: CGRect {
        return cropBoxView.frame
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupGestures()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        addSubview(dimView)
        addSubview(cropBoxView)
        cropBoxView.addSubview(topLeftHandle)
        cropBoxView.addSubview(topRightHandle)
        cropBoxView.addSubview(bottomLeftHandle)
        cropBoxView.addSubview(bottomRightHandle)

        dimView.frame = bounds
    }

    private func setupGestures() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        cropBoxView.addGestureRecognizer(panGesture)

        [topLeftHandle, topRightHandle, bottomLeftHandle, bottomRightHandle].forEach { handle in
            let handlePan = UIPanGestureRecognizer(target: self, action: #selector(handleCornerPan))
            handle.addGestureRecognizer(handlePan)
        }
    }

    func setCropRect(_ rect: CGRect) {
        cropBoxView.frame = rect
        layoutHandles()
        updateDimMask()
    }

    private func layoutHandles() {
        let handleSize: CGFloat = 30

        topLeftHandle.frame = CGRect(x: -handleSize/2, y: -handleSize/2, width: handleSize, height: handleSize)
        topRightHandle.frame = CGRect(x: cropBoxView.bounds.width - handleSize/2, y: -handleSize/2, width: handleSize, height: handleSize)
        bottomLeftHandle.frame = CGRect(x: -handleSize/2, y: cropBoxView.bounds.height - handleSize/2, width: handleSize, height: handleSize)
        bottomRightHandle.frame = CGRect(x: cropBoxView.bounds.width - handleSize/2, y: cropBoxView.bounds.height - handleSize/2, width: handleSize, height: handleSize)
    }

    private func updateDimMask() {
        let maskLayer = CAShapeLayer()
        let path = UIBezierPath(rect: bounds)
        path.append(UIBezierPath(rect: cropBoxView.frame).reversing())
        maskLayer.path = path.cgPath
        maskLayer.fillRule = .evenOdd
        dimView.layer.mask = maskLayer
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: self)

        switch gesture.state {
        case .began:
            initialCropRect = cropBoxView.frame
        case .changed:
            var newFrame = initialCropRect
            newFrame.origin.x += translation.x
            newFrame.origin.y += translation.y

            newFrame.origin.x = max(0, min(bounds.width - newFrame.width, newFrame.origin.x))
            newFrame.origin.y = max(0, min(bounds.height - newFrame.height, newFrame.origin.y))

            cropBoxView.frame = newFrame
            updateDimMask()
        default:
            break
        }
    }

    @objc private func handleCornerPan(_ gesture: UIPanGestureRecognizer) {
        guard let handle = gesture.view as? CropHandleView else { return }
        let translation = gesture.translation(in: self)

        switch gesture.state {
        case .began:
            initialCropRect = cropBoxView.frame
            currentHandle = handle
        case .changed:
            var newFrame = initialCropRect
            let minSize: CGFloat = 100

            if handle == topLeftHandle {
                newFrame.origin.x += translation.x
                newFrame.origin.y += translation.y
                newFrame.size.width -= translation.x
                newFrame.size.height -= translation.y
            } else if handle == topRightHandle {
                newFrame.origin.y += translation.y
                newFrame.size.width += translation.x
                newFrame.size.height -= translation.y
            } else if handle == bottomLeftHandle {
                newFrame.origin.x += translation.x
                newFrame.size.width -= translation.x
                newFrame.size.height += translation.y
            } else if handle == bottomRightHandle {
                newFrame.size.width += translation.x
                newFrame.size.height += translation.y
            }

            if newFrame.width >= minSize && newFrame.height >= minSize {
                newFrame.origin.x = max(0, min(bounds.width - newFrame.width, newFrame.origin.x))
                newFrame.origin.y = max(0, min(bounds.height - newFrame.height, newFrame.origin.y))

                if newFrame.maxX <= bounds.width && newFrame.maxY <= bounds.height {
                    cropBoxView.frame = newFrame
                    layoutHandles()
                    updateDimMask()
                }
            }
        default:
            currentHandle = nil
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        dimView.frame = bounds
        updateDimMask()
    }
}

final class CropHandleView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        layer.cornerRadius = 15
        layer.borderWidth = 2
        layer.borderColor = UIColor.systemBlue.cgColor
        isUserInteractionEnabled = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
