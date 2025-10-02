//
//  PhotoAnnotationView.swift
//  Sahara
//
//  Created by 금가경 on 10/2/25.
//

import MapKit
import UIKit

final class PhotoAnnotationView: MKAnnotationView {
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        return imageView
    }()

    private let bubbleView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 12
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 4
        view.layer.shadowOpacity = 0.3
        return view
    }()

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .clear
        frame = CGSize(width: 60, height: 75).asRect()
        centerOffset = CGPoint(x: 0, y: -frame.height / 2)

        addSubview(bubbleView)
        bubbleView.addSubview(imageView)

        bubbleView.frame = CGRect(x: 5, y: 0, width: 50, height: 50)
        imageView.frame = bubbleView.bounds.insetBy(dx: 5, dy: 5)
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)

        // 말풍선 꼬리 그리기
        let tailPath = UIBezierPath()
        let bubbleBottom = bubbleView.frame.maxY
        let bubbleCenter = bubbleView.frame.midX

        tailPath.move(to: CGPoint(x: bubbleCenter - 8, y: bubbleBottom - 5))
        tailPath.addLine(to: CGPoint(x: bubbleCenter, y: rect.maxY - 5))
        tailPath.addLine(to: CGPoint(x: bubbleCenter + 8, y: bubbleBottom - 5))
        tailPath.close()

        UIColor.white.setFill()
        tailPath.fill()

        // 꼬리 그림자
        let context = UIGraphicsGetCurrentContext()
        context?.saveGState()
        context?.setShadow(offset: CGSize(width: 0, height: 2), blur: 4, color: UIColor.black.withAlphaComponent(0.3).cgColor)
        tailPath.fill()
        context?.restoreGState()
    }

    func configure(with image: UIImage?) {
        imageView.image = image
        setNeedsDisplay()
    }
}

private extension CGSize {
    func asRect() -> CGRect {
        return CGRect(origin: .zero, size: self)
    }
}
