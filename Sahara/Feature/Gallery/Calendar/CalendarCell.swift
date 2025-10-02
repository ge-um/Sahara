//
//  CalendarCell.swift
//  Sahara
//
//  Created by 금가경 on 9/29/25.
//

import SnapKit
import UIKit

final class CalendarCell: UICollectionViewCell, IsIdentifiable {
    private let containerView = UIView()

    private var dayLabel: UILabel = {
        let label = UILabel()
        label.font = FontSystem.galmuriMono(size: 20)
        return label
    }()

    private var imageViews: [UIImageView] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func configureUI() {
        contentView.backgroundColor = .white

        addSubview(containerView)
        addSubview(dayLabel)

        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        dayLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(4)
            make.leading.equalToSuperview().offset(4)
        }
    }

    func configure(with item: DayItem) {
        // 기존 이미지뷰들 제거
        imageViews.forEach { $0.removeFromSuperview() }
        imageViews.removeAll()

        if let date = item.date {
            let day = Calendar.current.component(.day, from: date)
            dayLabel.text = "\(day)"

            // 현재 달이 아니면 회색으로 표시
            dayLabel.textColor = item.isCurrentMonth ? .label : .systemGray3

            let photoCount = item.cards.count

            if photoCount == 0 {
                containerView.backgroundColor = .white
            } else if photoCount == 1 {
                layoutSingleImage(item.cards[0])
            } else if photoCount == 2 {
                layoutTwoImages(item.cards[0], item.cards[1])
            } else {
                layoutMultipleImages(cards: Array(item.cards.prefix(3)))
            }
        } else {
            dayLabel.text = ""
            dayLabel.textColor = .label
            containerView.backgroundColor = .white
        }
    }

    private func layoutSingleImage(_ photoMemo: Card) {
        let imageView = createImageView()
        imageViews.append(imageView)
        containerView.addSubview(imageView)

        imageView.image = UIImage(data: photoMemo.editedImageData)
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func layoutTwoImages(_ photo1: Card, _ photo2: Card) {
        let imageView1 = createImageView()
        let imageView2 = createImageView()

        imageViews.append(contentsOf: [imageView1, imageView2])
        containerView.addSubview(imageView1)
        containerView.addSubview(imageView2)

        imageView1.image = UIImage(data: photo1.editedImageData)
        imageView2.image = UIImage(data: photo2.editedImageData)

        imageView1.snp.makeConstraints { make in
            make.top.leading.bottom.equalToSuperview()
            make.trailing.equalTo(containerView.snp.centerX).offset(-0.5)
        }

        imageView2.snp.makeConstraints { make in
            make.top.trailing.bottom.equalToSuperview()
            make.leading.equalTo(containerView.snp.centerX).offset(0.5)
        }
    }

    private func layoutMultipleImages(cards: [Card]) {
        guard cards.count >= 3 else { return }

        let topImageView = createImageView()
        let bottomLeftImageView = createImageView()
        let bottomRightImageView = createImageView()

        imageViews.append(contentsOf: [topImageView, bottomLeftImageView, bottomRightImageView])
        containerView.addSubview(topImageView)
        containerView.addSubview(bottomLeftImageView)
        containerView.addSubview(bottomRightImageView)

        topImageView.image = UIImage(data: cards[0].editedImageData)
        bottomLeftImageView.image = UIImage(data: cards[1].editedImageData)
        bottomRightImageView.image = UIImage(data: cards[2].editedImageData)

        topImageView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(containerView.snp.centerY).offset(-0.5)
        }

        bottomLeftImageView.snp.makeConstraints { make in
            make.leading.bottom.equalToSuperview()
            make.top.equalTo(containerView.snp.centerY).offset(0.5)
            make.trailing.equalTo(containerView.snp.centerX).offset(-0.5)
        }

        bottomRightImageView.snp.makeConstraints { make in
            make.trailing.bottom.equalToSuperview()
            make.top.equalTo(containerView.snp.centerY).offset(0.5)
            make.leading.equalTo(containerView.snp.centerX).offset(0.5)
        }
    }

    private func createImageView() -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleToFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .systemGray6
        return imageView
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageViews.forEach { $0.removeFromSuperview() }
        imageViews.removeAll()
        dayLabel.text = ""
    }
}
