//
//  FolderCell.swift
//  Sahara
//
//  Created by 금가경 on 10/13/25.
//

import SnapKit
import UIKit

final class FolderCell: UICollectionViewCell, IsIdentifiable {
    private let cardView: UIView = {
        let view = UIView()
        view.backgroundColor = ColorSystem.white30
        view.layer.cornerRadius = 12
        return view
    }()

    private let folderIconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "folder.fill")
        imageView.tintColor = ColorSystem.skyBlue
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let folderNameLabel: UILabel = {
        let label = UILabel()
        label.font = FontSystem.galmuriMono(size: 14)
        label.textColor = ColorSystem.darkGray
        return label
    }()

    private let folderInfoStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 8
        stackView.alignment = .center
        return stackView
    }()

    private let thumbnailContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()

    private var imageViews: [UIImageView] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureUI() {
        backgroundColor = .clear

        contentView.addSubview(cardView)
        cardView.addSubview(folderInfoStackView)
        cardView.addSubview(thumbnailContainerView)

        folderInfoStackView.addArrangedSubview(folderIconImageView)
        folderInfoStackView.addArrangedSubview(folderNameLabel)

        cardView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        folderIconImageView.snp.makeConstraints { make in
            make.width.height.equalTo(20)
        }

        folderInfoStackView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(12)
        }

        thumbnailContainerView.snp.makeConstraints { make in
            make.top.equalTo(folderInfoStackView.snp.bottom).offset(8)
            make.leading.trailing.bottom.equalToSuperview().inset(12)
        }
    }

    func configure(with folderGroup: FolderGroup) {
        folderNameLabel.text = folderGroup.folderName

        imageViews.forEach { $0.removeFromSuperview() }
        imageViews.removeAll()

        let photoCount = folderGroup.cards.count

        if photoCount == 0 {
            return
        } else if photoCount == 1 {
            layoutSingleImage(folderGroup.cards[0])
        } else if photoCount == 2 {
            layoutTwoImages(folderGroup.cards[0], folderGroup.cards[1])
        } else {
            layoutMultipleImages(cards: Array(folderGroup.cards.prefix(3)))
        }
    }

    private func layoutSingleImage(_ card: Card) {
        let imageView = createImageView()
        imageViews.append(imageView)
        thumbnailContainerView.addSubview(imageView)

        imageView.image = UIImage(data: card.editedImageData)

        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func layoutTwoImages(_ card1: Card, _ card2: Card) {
        let imageView1 = createImageView()
        let imageView2 = createImageView()

        imageViews.append(contentsOf: [imageView1, imageView2])
        thumbnailContainerView.addSubview(imageView1)
        thumbnailContainerView.addSubview(imageView2)

        imageView1.image = UIImage(data: card1.editedImageData)
        imageView2.image = UIImage(data: card2.editedImageData)

        imageView1.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(thumbnailContainerView.snp.centerY).offset(-2)
        }

        imageView2.snp.makeConstraints { make in
            make.bottom.leading.trailing.equalToSuperview()
            make.top.equalTo(thumbnailContainerView.snp.centerY).offset(2)
        }
    }

    private func layoutMultipleImages(cards: [Card]) {
        guard cards.count >= 3 else { return }

        let topImageView = createImageView()
        let bottomLeftImageView = createImageView()
        let bottomRightImageView = createImageView()

        imageViews.append(contentsOf: [topImageView, bottomLeftImageView, bottomRightImageView])
        thumbnailContainerView.addSubview(topImageView)
        thumbnailContainerView.addSubview(bottomLeftImageView)
        thumbnailContainerView.addSubview(bottomRightImageView)

        topImageView.image = UIImage(data: cards[0].editedImageData)
        bottomLeftImageView.image = UIImage(data: cards[1].editedImageData)
        bottomRightImageView.image = UIImage(data: cards[2].editedImageData)

        topImageView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(thumbnailContainerView.snp.centerY).offset(-2)
        }

        bottomLeftImageView.snp.makeConstraints { make in
            make.leading.bottom.equalToSuperview()
            make.top.equalTo(thumbnailContainerView.snp.centerY).offset(2)
            make.trailing.equalTo(thumbnailContainerView.snp.centerX).offset(-2)
        }

        bottomRightImageView.snp.makeConstraints { make in
            make.trailing.bottom.equalToSuperview()
            make.top.equalTo(thumbnailContainerView.snp.centerY).offset(2)
            make.leading.equalTo(thumbnailContainerView.snp.centerX).offset(2)
        }
    }

    private func createImageView() -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 4
        imageView.backgroundColor = ColorSystem.systemGray6
        return imageView
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageViews.forEach { $0.removeFromSuperview() }
        imageViews.removeAll()
        folderNameLabel.text = ""
    }
}
