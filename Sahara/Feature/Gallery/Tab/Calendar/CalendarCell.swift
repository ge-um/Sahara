//
//  CalendarCell.swift
//  Sahara
//
//  Created by 금가경 on 9/29/25.
//

import Kingfisher
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
        label.textColor = .token(.border)
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()

    private var imageViews: [UIImageView] = []
    private var blurViews: [UIVisualEffectView] = []
    private var isToday = false

    private var thumbnailPixelSize: CGFloat {
        ThumbnailCache.maxPixelSize(for: bounds.size, scale: traitCollection.displayScale)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func configureUI() {
        contentView.backgroundColor = .clear

        addSubview(containerView)
        addSubview(dayLabel)
        addSubview(addButton)

        containerView.backgroundColor = .clear

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
        addButton.isHidden = true
        contentView.layer.cornerRadius = 8

        if let date = item.date {
            let day = Calendar.current.component(.day, from: date)
            dayLabel.text = "\(day)"

            let weekday = Calendar.current.component(.weekday, from: date)

            let calendar = Calendar.current
            let isTodayDate = calendar.isDateInToday(date) && item.isCurrentMonth
            isToday = isTodayDate

            if !item.isCurrentMonth {
                dayLabel.textColor = .token(.textTertiary)
            } else if weekday == 1 {
                dayLabel.textColor = .token(.destructive)
            } else if weekday == 7 {
                dayLabel.textColor = .token(.info)
            } else {
                dayLabel.textColor = .token(.textPrimary)
            }

            let sortedCards = item.cards.sorted { !$0.isLocked && $1.isLocked }
            let photoCount = sortedCards.count

            let shouldShowBorder = isTodayDate && photoCount == 0

            contentView.layer.borderColor = shouldShowBorder ? UIColor.token(.border).cgColor : nil
            contentView.layer.borderWidth = shouldShowBorder ? 2 : 0

            if photoCount == 0 {
                containerView.backgroundColor = .clear
                addButton.isHidden = !isTodayDate
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
            dayLabel.textColor = .token(.textPrimary)
            containerView.backgroundColor = .clear
            addButton.isHidden = true
            contentView.layer.borderColor = nil
            contentView.layer.borderWidth = 0
        }
    }

    private func layoutSingleImage(_ card: CardCalendarItemDTO) {
        let imageView = createImageView()
        imageViews.append(imageView)
        containerView.addSubview(imageView)

        ThumbnailCache.shared.loadThumbnail(for: card.id, maxPixelSize: thumbnailPixelSize) { [weak imageView] image in
            imageView?.image = image
        }
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

    private func layoutTwoImages(_ photo1: CardCalendarItemDTO, _ photo2: CardCalendarItemDTO) {
        let imageView1 = createImageView()
        let imageView2 = createImageView()

        imageViews.append(contentsOf: [imageView1, imageView2])
        containerView.addSubview(imageView1)
        containerView.addSubview(imageView2)

        ThumbnailCache.shared.loadThumbnail(for: photo1.id, maxPixelSize: thumbnailPixelSize) { [weak imageView1] image in
            imageView1?.image = image
        }
        ThumbnailCache.shared.loadThumbnail(for: photo2.id, maxPixelSize: thumbnailPixelSize) { [weak imageView2] image in
            imageView2?.image = image
        }

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

    private func layoutMultipleImages(cards: [CardCalendarItemDTO]) {
        guard cards.count >= 3 else { return }

        let topImageView = createImageView()
        let bottomLeftImageView = createImageView()
        let bottomRightImageView = createImageView()

        imageViews.append(contentsOf: [topImageView, bottomLeftImageView, bottomRightImageView])
        containerView.addSubview(topImageView)
        containerView.addSubview(bottomLeftImageView)
        containerView.addSubview(bottomRightImageView)

        ThumbnailCache.shared.loadThumbnail(for: cards[0].id, maxPixelSize: thumbnailPixelSize) { [weak topImageView] image in
            topImageView?.image = image
        }
        ThumbnailCache.shared.loadThumbnail(for: cards[1].id, maxPixelSize: thumbnailPixelSize) { [weak bottomLeftImageView] image in
            bottomLeftImageView?.image = image
        }
        ThumbnailCache.shared.loadThumbnail(for: cards[2].id, maxPixelSize: thumbnailPixelSize) { [weak bottomRightImageView] image in
            bottomRightImageView?.image = image
        }

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
        return imageView
    }

    private func createBlurView() -> UIVisualEffectView {
        return BlurUtility.createBlurView()
    }

    func setDropHighlight(_ highlighted: Bool) {
        if highlighted {
            containerView.layer.cornerRadius = 8
            containerView.layer.borderColor = DesignToken.Gradient.ctaBlue.colors[0]
            containerView.layer.borderWidth = 2
        } else {
            containerView.layer.cornerRadius = 0
            containerView.layer.borderColor = nil
            containerView.layer.borderWidth = 0
        }
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
