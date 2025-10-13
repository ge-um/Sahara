//
//  CalendarDetailCell.swift
//  Sahara
//
//  Created by 금가경 on 10/3/25.
//

import UIKit
import SnapKit

final class CalendarDetailCell: UICollectionViewCell, IsIdentifiable {
    private let cardImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 12
        imageView.backgroundColor = .systemGray6
        return imageView
    }()

    private let blurEffectView: UIVisualEffectView = {
        let blurEffect = UIBlurEffect(style: .extraLight)
        let effectView = UIVisualEffectView(effect: blurEffect)
        effectView.layer.cornerRadius = 12
        effectView.clipsToBounds = true
        effectView.isHidden = true
        return effectView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func configureUI() {
        contentView.backgroundColor = .clear
        backgroundColor = .clear

        contentView.addSubview(cardImageView)
        contentView.addSubview(blurEffectView)

        cardImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        blurEffectView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    func configure(with card: Card) {
        cardImageView.image = UIImage(data: card.editedImageData)
        blurEffectView.isHidden = !card.isLocked
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        cardImageView.image = nil
        blurEffectView.isHidden = true
    }
}
