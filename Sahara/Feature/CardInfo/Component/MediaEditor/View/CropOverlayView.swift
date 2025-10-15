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
        view.backgroundColor = .clear
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
    private var currentHandle: CropHandleView?
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
        cropBoxView.addSubview(topLeftHandle)
        cropBoxView.addSubview(topRightHandle)
        cropBoxView.addSubview(bottomLeftHandle)
        cropBoxView.addSubview(bottomRightHandle)
        cropBoxView.addSubview(topHandle)
        cropBoxView.addSubview(bottomHandle)
        cropBoxView.addSubview(leftHandle)
        cropBoxView.addSubview(rightHandle)

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
        let cornerSize: CGFloat = 40
        let edgeThickness: CGFloat = 4
        let edgeLength: CGFloat = 60
        let midX = cropBoxView.bounds.width / 2
        let midY = cropBoxView.bounds.height / 2

        // 모서리 핸들 - ㄱ자 (터치 영역 확보를 위해 큰 사각형)
        topLeftHandle.frame = CGRect(x: -cornerSize/2, y: -cornerSize/2, width: cornerSize, height: cornerSize)
        topRightHandle.frame = CGRect(x: cropBoxView.bounds.width - cornerSize/2, y: -cornerSize/2, width: cornerSize, height: cornerSize)
        bottomLeftHandle.frame = CGRect(x: -cornerSize/2, y: cropBoxView.bounds.height - cornerSize/2, width: cornerSize, height: cornerSize)
        bottomRightHandle.frame = CGRect(x: cropBoxView.bounds.width - cornerSize/2, y: cropBoxView.bounds.height - cornerSize/2, width: cornerSize, height: cornerSize)

        // 중간 핸들 - 굵은 선
        topHandle.frame = CGRect(x: midX - edgeLength/2, y: -edgeThickness/2, width: edgeLength, height: edgeThickness)
        bottomHandle.frame = CGRect(x: midX - edgeLength/2, y: cropBoxView.bounds.height - edgeThickness/2, width: edgeLength, height: edgeThickness)
        leftHandle.frame = CGRect(x: -edgeThickness/2, y: midY - edgeLength/2, width: edgeThickness, height: edgeLength)
        rightHandle.frame = CGRect(x: cropBoxView.bounds.width - edgeThickness/2, y: midY - edgeLength/2, width: edgeThickness, height: edgeLength)

        // 다시 그리기
        [topLeftHandle, topRightHandle, bottomLeftHandle, bottomRightHandle, topHandle, bottomHandle, leftHandle, rightHandle].forEach {
            $0.setNeedsDisplay()
        }
    }

    private func updateDimMask() {
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
            let minSize: CGFloat = 50

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
                newFrame.origin.x = max(imageRect.origin.x, newFrame.origin.x)
                newFrame.origin.y = max(imageRect.origin.y, newFrame.origin.y)

                if newFrame.maxX > imageRect.maxX {
                    newFrame.size.width = imageRect.maxX - newFrame.origin.x
                }
                if newFrame.maxY > imageRect.maxY {
                    newFrame.size.height = imageRect.maxY - newFrame.origin.y
                }

                if newFrame.width >= minSize && newFrame.height >= minSize {
                    cropBoxView.frame = newFrame
                    layoutHandles()
                }
            }
        default:
            currentHandle = nil
        }
    }

    @objc private func handleEdgePan(_ gesture: UIPanGestureRecognizer) {
        guard let handle = gesture.view as? CropHandleView else { return }
        let translation = gesture.translation(in: self)

        switch gesture.state {
        case .began:
            initialCropRect = cropBoxView.frame
            currentHandle = handle
        case .changed:
            var newFrame = initialCropRect
            let minSize: CGFloat = 50

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

            if newFrame.width >= minSize && newFrame.height >= minSize {
                newFrame.origin.x = max(imageRect.origin.x, newFrame.origin.x)
                newFrame.origin.y = max(imageRect.origin.y, newFrame.origin.y)

                if newFrame.maxX > imageRect.maxX {
                    newFrame.size.width = imageRect.maxX - newFrame.origin.x
                }
                if newFrame.maxY > imageRect.maxY {
                    newFrame.size.height = imageRect.maxY - newFrame.origin.y
                }

                if newFrame.width >= minSize && newFrame.height >= minSize {
                    cropBoxView.frame = newFrame
                    layoutHandles()
                }
            }
        default:
            currentHandle = nil
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        dimView.frame = bounds
    }
}

final class CropHandleView: UIView {
    enum HandleType {
        case corner
        case edge
    }

    var handleType: HandleType = .edge
    var cornerPosition: String = "" // "topLeft", "topRight", "bottomLeft", "bottomRight"

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

            // ㄱ자 그리기 (모서리 기준)
            if cornerPosition == "topLeft" {
                // 왼쪽 위 모서리: ┌ 형태
                context.move(to: CGPoint(x: centerX, y: centerY + length))
                context.addLine(to: CGPoint(x: centerX, y: centerY + offset))
                context.addLine(to: CGPoint(x: centerX + length, y: centerY + offset))
            } else if cornerPosition == "topRight" {
                // 오른쪽 위 모서리: ┐ 형태
                context.move(to: CGPoint(x: centerX - length, y: centerY + offset))
                context.addLine(to: CGPoint(x: centerX, y: centerY + offset))
                context.addLine(to: CGPoint(x: centerX, y: centerY + length))
            } else if cornerPosition == "bottomLeft" {
                // 왼쪽 아래 모서리: └ 형태
                context.move(to: CGPoint(x: centerX, y: centerY - length))
                context.addLine(to: CGPoint(x: centerX, y: centerY - offset))
                context.addLine(to: CGPoint(x: centerX + length, y: centerY - offset))
            } else if cornerPosition == "bottomRight" {
                // 오른쪽 아래 모서리: ┘ 형태
                context.move(to: CGPoint(x: centerX - length, y: centerY - offset))
                context.addLine(to: CGPoint(x: centerX, y: centerY - offset))
                context.addLine(to: CGPoint(x: centerX, y: centerY - length))
            }
            context.strokePath()
        } else {
            // 굵은 선
            context.setFillColor(UIColor.white.cgColor)
            context.fill(rect)
        }
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let expandedBounds = bounds.insetBy(dx: -20, dy: -20)
        return expandedBounds.contains(point)
    }
}
