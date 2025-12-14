//
//  BaseCardThumbnailCell.swift
//  Sahara
//
//  Created by 금가경 on 12/14/25.
//

import SnapKit
import UIKit

class BaseCardThumbnailCell: UICollectionViewCell, IsIdentifiable {

    let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()

    lazy var blurEffectView: UIVisualEffectView = BlurUtility.createBlurView(cornerRadius: 8)

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configureUI() {
        contentView.addSubview(imageView)
        contentView.addSubview(blurEffectView)
        contentView.layer.cornerRadius = 8
        contentView.clipsToBounds = true

        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        blurEffectView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    func setImage(_ imageData: Data) {
        imageView.image = UIImage(data: imageData)
    }

    func setBlur(isHidden: Bool) {
        blurEffectView.isHidden = isHidden
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        blurEffectView.isHidden = true
    }
}
