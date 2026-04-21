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
        view.clipsToBounds = false
        return view
    }()

    private let dimView: UIView = {
        let view = UIView()
        view.backgroundColor = DesignToken.Overlay.heavyOverlay
        view.isUserInteractionEnabled = false
        return view
    }()

    private let topLeftHandle: CropHandleView = {
        let handle = CropHandleView()
        handle.handleType = .corner
        handle.cornerPosition = "topLeft"
        return handle
    }()
    private let topRightHandle: CropHandleView = {
        let handle = CropHandleView()
        handle.handleType = .corner
        handle.cornerPosition = "topRight"
        return handle
    }()
    private let bottomLeftHandle: CropHandleView = {
        let handle = CropHandleView()
        handle.handleType = .corner
        handle.cornerPosition = "bottomLeft"
        return handle
    }()
    private let bottomRightHandle: CropHandleView = {
        let handle = CropHandleView()
        handle.handleType = .corner
        handle.cornerPosition = "bottomRight"
        return handle
    }()
    private let topHandle = CropHandleView()
    private let bottomHandle = CropHandleView()
    private let leftHandle = CropHandleView()
    private let rightHandle = CropHandleView()

    private var initialCropRect: CGRect = .zero
    var imageRect: CGRect = .zero

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
        addSubview(topLeftHandle)
        addSubview(topRightHandle)
        addSubview(bottomLeftHandle)
        addSubview(bottomRightHandle)
        addSubview(topHandle)
        addSubview(bottomHandle)
        addSubview(leftHandle)
        addSubview(rightHandle)

        dimView.frame = bounds
    }

    private func setupGestures() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        cropBoxView.addGestureRecognizer(panGesture)

        [topLeftHandle, topRightHandle, bottomLeftHandle, bottomRightHandle].forEach { handle in
            let handlePan = UIPanGestureRecognizer(target: self, action: #selector(handleCornerPan))
            handle.addGestureRecognizer(handlePan)
        }

        [topHandle, bottomHandle, leftHandle, rightHandle].forEach { handle in
            let handlePan = UIPanGestureRecognizer(target: self, action: #selector(handleEdgePan))
            handle.addGestureRecognizer(handlePan)
        }
    }

    func setCropRect(_ rect: CGRect) {
        cropBoxView.frame = rect
        layoutHandles()
        updateDimMask()
    }

    private func layoutHandles() {
        let cornerSize: CGFloat = 50
        let edgeThickness: CGFloat = 4
        let edgeLength: CGFloat = 80
        let cropFrame = cropBoxView.frame
        let midX = cropFrame.midX
        let midY = cropFrame.midY

        topLeftHandle.frame = CGRect(
            x: cropFrame.minX - cornerSize/2,
            y: cropFrame.minY - cornerSize/2,
            width: cornerSize,
            height: cornerSize
        )
        topRightHandle.frame = CGRect(
            x: cropFrame.maxX - cornerSize/2,
            y: cropFrame.minY - cornerSize/2,
            width: cornerSize,
            height: cornerSize
        )
        bottomLeftHandle.frame = CGRect(
            x: cropFrame.minX - cornerSize/2,
            y: cropFrame.maxY - cornerSize/2,
            width: cornerSize,
            height: cornerSize
        )
        bottomRightHandle.frame = CGRect(
            x: cropFrame.maxX - cornerSize/2,
            y: cropFrame.maxY - cornerSize/2,
            width: cornerSize,
            height: cornerSize
        )

        topHandle.frame = CGRect(
            x: midX - edgeLength/2,
            y: cropFrame.minY - edgeThickness/2,
            width: edgeLength,
            height: edgeThickness
        )
        bottomHandle.frame = CGRect(
            x: midX - edgeLength/2,
            y: cropFrame.maxY - edgeThickness/2,
            width: edgeLength,
            height: edgeThickness
        )
        leftHandle.frame = CGRect(
            x: cropFrame.minX - edgeThickness/2,
            y: midY - edgeLength/2,
            width: edgeThickness,
            height: edgeLength
        )
        rightHandle.frame = CGRect(
            x: cropFrame.maxX - edgeThickness/2,
            y: midY - edgeLength/2,
            width: edgeThickness,
            height: edgeLength
        )

        [topLeftHandle, topRightHandle, bottomLeftHandle, bottomRightHandle, topHandle, bottomHandle, leftHandle, rightHandle].forEach {
            $0.setNeedsDisplay()
        }
    }

    private func updateDimMask() {
        let maskLayer = CAShapeLayer()
        let path = UIBezierPath(rect: imageRect)
        let cropPath = UIBezierPath(rect: cropBoxView.frame)
        path.append(cropPath)
        path.usesEvenOddFillRule = true

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

            newFrame.origin.x = max(imageRect.origin.x, min(imageRect.maxX - newFrame.width, newFrame.origin.x))
            newFrame.origin.y = max(imageRect.origin.y, min(imageRect.maxY - newFrame.height, newFrame.origin.y))

            cropBoxView.frame = newFrame
            layoutHandles()
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
        case .changed:
            var newFrame = initialCropRect

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

            constrainFrame(&newFrame)
        default:
            break
        }
    }

    @objc private func handleEdgePan(_ gesture: UIPanGestureRecognizer) {
        guard let handle = gesture.view as? CropHandleView else { return }
        let translation = gesture.translation(in: self)

        switch gesture.state {
        case .began:
            initialCropRect = cropBoxView.frame
        case .changed:
            var newFrame = initialCropRect

            if handle == topHandle {
                newFrame.origin.y += translation.y
                newFrame.size.height -= translation.y
            } else if handle == bottomHandle {
                newFrame.size.height += translation.y
            } else if handle == leftHandle {
                newFrame.origin.x += translation.x
                newFrame.size.width -= translation.x
            } else if handle == rightHandle {
                newFrame.size.width += translation.x
            }

            constrainFrame(&newFrame)
        default:
            break
        }
    }

    private func constrainFrame(_ frame: inout CGRect) {
        let minSize: CGFloat = 50

        guard frame.width >= minSize && frame.height >= minSize else { return }

        frame.origin.x = max(imageRect.origin.x, frame.origin.x)
        frame.origin.y = max(imageRect.origin.y, frame.origin.y)

        if frame.maxX > imageRect.maxX {
            frame.size.width = imageRect.maxX - frame.origin.x
        }
        if frame.maxY > imageRect.maxY {
            frame.size.height = imageRect.maxY - frame.origin.y
        }

        guard frame.width >= minSize && frame.height >= minSize else { return }

        cropBoxView.frame = frame
        layoutHandles()
        updateDimMask()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        dimView.frame = bounds
        updateDimMask()
    }
}

final class CropHandleView: UIView {
    enum HandleType {
        case corner
        case edge
    }

    var handleType: HandleType = .edge
    var cornerPosition: String = ""

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isUserInteractionEnabled = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)

        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.setStrokeColor(UIColor.white.cgColor)
        context.setLineWidth(4)

        if handleType == .corner {
            let length: CGFloat = 25
            let offset: CGFloat = 2
            let centerX = rect.width / 2
            let centerY = rect.height / 2

            if cornerPosition == "topLeft" {
                context.move(to: CGPoint(x: centerX, y: centerY + length))
                context.addLine(to: CGPoint(x: centerX, y: centerY + offset))
                context.addLine(to: CGPoint(x: centerX + length, y: centerY + offset))
            } else if cornerPosition == "topRight" {
                context.move(to: CGPoint(x: centerX - length, y: centerY + offset))
                context.addLine(to: CGPoint(x: centerX, y: centerY + offset))
                context.addLine(to: CGPoint(x: centerX, y: centerY + length))
            } else if cornerPosition == "bottomLeft" {
                context.move(to: CGPoint(x: centerX, y: centerY - length))
                context.addLine(to: CGPoint(x: centerX, y: centerY - offset))
                context.addLine(to: CGPoint(x: centerX + length, y: centerY - offset))
            } else if cornerPosition == "bottomRight" {
                context.move(to: CGPoint(x: centerX - length, y: centerY - offset))
                context.addLine(to: CGPoint(x: centerX, y: centerY - offset))
                context.addLine(to: CGPoint(x: centerX, y: centerY - length))
            }
            context.strokePath()
        } else {
            context.setFillColor(UIColor.white.cgColor)
            context.fill(rect)
        }
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let expandedBounds = bounds.insetBy(dx: -40, dy: -40)
        return expandedBounds.contains(point)
    }
}
