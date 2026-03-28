//
//  BaseMediaAnnotationView.swift
//  Sahara
//
//  Created by 금가경 on 10/4/25.
//

import MapKit
import UIKit

class BaseMediaAnnotationView: MKAnnotationView {
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 25
        return imageView
    }()

    private lazy var blurEffectView: UIVisualEffectView = {
        return BlurUtility.createBlurView(cornerRadius: 25)
    }()

    private let overlayView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        view.layer.cornerRadius = 25
        return view
    }()

    private let countLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.textColor = .white
        label.font = DesignToken.Typography.caption.numericFont
        return label
    }()

    private let borderView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.layer.borderColor = UIColor.white.cgColor
        view.layer.borderWidth = 3
        view.layer.cornerRadius = 25
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
        frame = CGSize(width: 50, height: 50).asRect()

        addSubview(imageView)
        addSubview(blurEffectView)
        addSubview(overlayView)
        addSubview(countLabel)
        addSubview(borderView)

        imageView.frame = bounds
        blurEffectView.frame = bounds
        overlayView.frame = bounds
        countLabel.frame = bounds
        borderView.frame = bounds
    }

    func configure(image: UIImage?, count: Int, isLocked: Bool = false) {
        imageView.image = image
        countLabel.text = "\(count)"
        blurEffectView.isHidden = !isLocked
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        countLabel.text = nil
        blurEffectView.isHidden = true
    }
}

private extension CGSize {
    func asRect() -> CGRect {
        return CGRect(origin: .zero, size: self)
    }
}
