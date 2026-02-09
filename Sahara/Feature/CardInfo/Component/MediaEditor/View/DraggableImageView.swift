//
//  DraggableImageView.swift
//  Sahara
//
//  Created by 금가경 on 9/26/25.
//

import UIKit

final class DraggableImageView: BaseGestureView {
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    var image: UIImage? {
        return imageView.image
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureUI() {
        layer.cornerRadius = 8
        clipsToBounds = true

        addSubview(imageView)
        imageView.frame = bounds
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }

    func configure(with image: UIImage) {
        imageView.image = image
    }
}
