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
        label.font = FontSystem.galmuriMono(size: 16)
        return label
    }()

    private let addButton: UILabel = {
        let label = UILabel()
        label.text = "+"
        label.font = FontSystem.galmuriMono(size: 18)
        label.textColor = ColorSystem.todayIndicator
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()

    private var imageViews: [UIImageView] = []
    private var blurViews: [UIVisualEffectView] = []
    private var isToday = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func configureUI() {
        contentView.backgroundColor = ColorSystem.clear

        addSubview(containerView)
        addSubview(dayLabel)
        addSubview(addButton)

        containerView.backgroundColor = ColorSystem.clear

        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        dayLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.leading.equalToSuperview().offset(8)
        }

        addButton.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }

    func configure(with item: DayItem) {
        imageViews.forEach { $0.removeFromSuperview() }
        imageViews.removeAll()
        blurViews.forEach { $0.removeFromSuperview() }
        blurViews.removeAll()

        isToday = false
        contentView.layer.borderWidth = 0

        if let date = item.date {
            let day = Calendar.current.component(.day, from: date)
            dayLabel.text = "\(day)"

            let weekday = Calendar.current.component(.weekday, from: date)

            let calendar = Calendar.current
            if calendar.isDateInToday(date) {
                isToday = true
                contentView.layer.borderColor = ColorSystem.todayIndicator.cgColor
                contentView.layer.borderWidth = 2
                contentView.layer.cornerRadius = 8
            }

            if !item.isCurrentMonth {
                dayLabel.textColor = ColorSystem.labelNotCurrentMonth
            } else if weekday == 1 {
                dayLabel.textColor = ColorSystem.systemRed
            } else if weekday == 7 {
                dayLabel.textColor = ColorSystem.systemBlue
            } else {
                dayLabel.textColor = ColorSystem.label
            }

            let sortedCards = item.cards.sorted { !$0.isLocked && $1.isLocked }
            let photoCount = sortedCards.count

            if photoCount == 0 {
                containerView.backgroundColor = ColorSystem.clear
                addButton.isHidden = !isToday
            } else {
                addButton.isHidden = true
                if photoCount == 1 {
                    layoutSingleImage(sortedCards[0])
                } else if photoCount == 2 {
                    layoutTwoImages(sortedCards[0], sortedCards[1])
                } else {
                    layoutMultipleImages(cards: Array(sortedCards.prefix(3)))
                }
            }
        } else {
            dayLabel.text = ""
            dayLabel.textColor = ColorSystem.label
            containerView.backgroundColor = ColorSystem.clear
            addButton.isHidden = true
        }
    }

    private func layoutSingleImage(_ card: Card) {
        let imageView = createImageView()
        imageViews.append(imageView)
        containerView.addSubview(imageView)

        imageView.image = UIImage(data: card.editedImageData)
        imageView.layer.cornerRadius = 8
        imageView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]

        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        if card.isLocked {
            let blurView = createBlurView()
            blurView.layer.cornerRadius = 8
            blurViews.append(blurView)
            containerView.addSubview(blurView)
            blurView.snp.makeConstraints { make in
                make.edges.equalTo(imageView)
            }
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

        imageView1.layer.cornerRadius = 8
        imageView1.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]

        imageView2.layer.cornerRadius = 8
        imageView2.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]

        imageView1.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(containerView.snp.centerY).offset(-0.5)
        }

        imageView2.snp.makeConstraints { make in
            make.bottom.leading.trailing.equalToSuperview()
            make.top.equalTo(containerView.snp.centerY).offset(0.5)
        }

        if photo1.isLocked {
            let blurView = createBlurView()
            blurView.layer.cornerRadius = 8
            blurView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
            blurViews.append(blurView)
            containerView.addSubview(blurView)
            blurView.snp.makeConstraints { make in
                make.edges.equalTo(imageView1)
            }
        }

        if photo2.isLocked {
            let blurView = createBlurView()
            blurView.layer.cornerRadius = 8
            blurView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
            blurViews.append(blurView)
            containerView.addSubview(blurView)
            blurView.snp.makeConstraints { make in
                make.edges.equalTo(imageView2)
            }
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

        topImageView.layer.cornerRadius = 8
        topImageView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]

        bottomLeftImageView.layer.cornerRadius = 8
        bottomLeftImageView.layer.maskedCorners = [.layerMinXMaxYCorner]

        bottomRightImageView.layer.cornerRadius = 8
        bottomRightImageView.layer.maskedCorners = [.layerMaxXMaxYCorner]

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

        if cards[0].isLocked {
            let blurView = createBlurView()
            blurView.layer.cornerRadius = 8
            blurView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
            blurViews.append(blurView)
            containerView.addSubview(blurView)
            blurView.snp.makeConstraints { make in
                make.edges.equalTo(topImageView)
            }
        }

        if cards[1].isLocked {
            let blurView = createBlurView()
            blurView.layer.cornerRadius = 8
            blurView.layer.maskedCorners = [.layerMinXMaxYCorner]
            blurViews.append(blurView)
            containerView.addSubview(blurView)
            blurView.snp.makeConstraints { make in
                make.edges.equalTo(bottomLeftImageView)
            }
        }

        if cards[2].isLocked {
            let blurView = createBlurView()
            blurView.layer.cornerRadius = 8
            blurView.layer.maskedCorners = [.layerMaxXMaxYCorner]
            blurViews.append(blurView)
            containerView.addSubview(blurView)
            blurView.snp.makeConstraints { make in
                make.edges.equalTo(bottomRightImageView)
            }
        }
    }

    private func createImageView() -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = ColorSystem.systemGray6
        return imageView
    }

    private func createBlurView() -> UIVisualEffectView {
        let blurEffect = UIBlurEffect(style: .extraLight)
        let effectView = UIVisualEffectView(effect: blurEffect)
        effectView.clipsToBounds = true
        return effectView
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageViews.forEach { $0.removeFromSuperview() }
        imageViews.removeAll()
        blurViews.forEach { $0.removeFromSuperview() }
        blurViews.removeAll()
        dayLabel.text = ""
        contentView.layer.borderWidth = 0
        isToday = false
        addButton.isHidden = true
    }
}
