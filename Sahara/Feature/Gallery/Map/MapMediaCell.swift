//
//  MapMediaCell.swift
//  Sahara
//
//  Created by 금가경 on 10/13/25.
//

import UIKit

final class MapMediaCell: UICollectionViewCell, IsIdentifiable {

    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .systemGray6
        return imageView
    }()

    private let blurEffectView: UIVisualEffectView = {
        let blurEffect = UIBlurEffect(style: .extraLight)
        let effectView = UIVisualEffectView(effect: blurEffect)
        effectView.layer.cornerRadius = 8
        effectView.clipsToBounds = true
        effectView.isHidden = true
        return effectView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureUI() {
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

    func configure(with card: Card) {
        if let image = UIImage(data: card.editedImageData) {
            imageView.image = image
        }
        blurEffectView.isHidden = !card.isLocked
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        blurEffectView.isHidden = true
    }
}
