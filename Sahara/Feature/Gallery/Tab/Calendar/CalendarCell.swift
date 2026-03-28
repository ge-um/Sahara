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

    // MARK: - Layout Decision

    private enum CellImageLayout {
        case single
        case twoVertical      // 상/하 분할 (세로형 셀)
        case twoHorizontal    // 좌/우 분할 (가로형 셀)
        case threeTopOne      // 위1 + 아래2 (세로형 셀)
        case threeLeftOne     // 왼쪽1 + 오른쪽2 (가로형 셀)
        case fourGrid         // 2×2 그리드
    }

    private func decideLayout(photoCount: Int) -> CellImageLayout {
        let cellSize = bounds.size
        guard cellSize.width > 0, cellSize.height > 0 else { return .single }

        let minDim = min(cellSize.width, cellSize.height)
        let isLandscape = cellSize.width > cellSize.height

        if photoCount <= 1 || minDim < 40 { return .single }

        if photoCount == 2 {
            return isLandscape ? .twoHorizontal : .twoVertical
        }

        if photoCount == 3 {
            return isLandscape ? .threeLeftOne : .threeTopOne
        }

        if minDim < 80 {
            return isLandscape ? .threeLeftOne : .threeTopOne
        }

        return .fourGrid
    }
    private let containerView = UIView()

    private var dayLabel: UILabel = {
        let label = UILabel()
        label.font = .typography(.title)
        return label
    }()

    private let addButton: UILabel = {
        let label = UILabel()
        label.text = "+"
        label.font = .typography(.emphasis)
        label.textColor = .token(.border)
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()

    private var imageViews: [UIImageView] = []
    private var blurViews: [UIVisualEffectView] = []
    private var isToday = false
    private var cachedSortedCards: [CardCalendarItemDTO] = []
    private var cachedLayoutDecision: CellImageLayout?
    private var cachedBoundsSize: CGSize = .zero

    private var thumbnailPixelSize: CGFloat {
        ThumbnailCache.maxPixelSize(for: bounds.size, scale: traitCollection.displayScale)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard bounds.size != cachedBoundsSize else { return }
        guard !cachedSortedCards.isEmpty else {
            cachedBoundsSize = bounds.size
            return
        }
        let newDecision = decideLayout(photoCount: cachedSortedCards.count)
        guard newDecision != cachedLayoutDecision else {
            cachedBoundsSize = bounds.size
            return
        }
        applyImageLayout(sortedCards: cachedSortedCards)
    }

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
        cachedSortedCards = []
        cachedLayoutDecision = nil
        cachedBoundsSize = .zero

        clearImageAndBlurViews()

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
            cachedSortedCards = sortedCards

            let shouldShowBorder = isTodayDate && sortedCards.isEmpty

            contentView.layer.borderColor = shouldShowBorder ? UIColor.token(.border).cgColor : nil
            contentView.layer.borderWidth = shouldShowBorder ? 2 : 0

            if sortedCards.isEmpty {
                containerView.backgroundColor = .clear
                addButton.isHidden = !isTodayDate
            } else {
                addButton.isHidden = true
                applyImageLayout(sortedCards: sortedCards)
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

    private func applyImageLayout(sortedCards: [CardCalendarItemDTO]) {
        clearImageAndBlurViews()

        let photoCount = sortedCards.count
        let layout = decideLayout(photoCount: photoCount)
        cachedLayoutDecision = layout
        cachedBoundsSize = bounds.size

        switch layout {
        case .single:
            layoutSingleImage(sortedCards[0])
        case .twoVertical:
            layoutTwoImages(sortedCards[0], sortedCards[min(1, photoCount - 1)])
        case .twoHorizontal:
            layoutTwoHorizontalImages(sortedCards[0], sortedCards[min(1, photoCount - 1)])
        case .threeTopOne:
            layoutMultipleImages(cards: Array(sortedCards.prefix(3)))
        case .threeLeftOne:
            layoutThreeLeftOneImages(cards: Array(sortedCards.prefix(3)))
        case .fourGrid:
            layoutFourGridImages(cards: Array(sortedCards.prefix(4)))
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

        addBlurIfLocked(card, over: imageView)
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

        addBlurIfLocked(photo1, over: imageView1, corners: [.layerMinXMinYCorner, .layerMaxXMinYCorner])
        addBlurIfLocked(photo2, over: imageView2, corners: [.layerMinXMaxYCorner, .layerMaxXMaxYCorner])
    }

    // MARK: - 좌/우 분할 (가로형 셀, 2장)
    //  ┌──────┬──────┐
    //  │      │      │
    //  │ img1 │ img2 │
    //  │      │      │
    //  └──────┴──────┘

    private func layoutTwoHorizontalImages(_ photo1: CardCalendarItemDTO, _ photo2: CardCalendarItemDTO) {
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
        imageView1.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]

        imageView2.layer.cornerRadius = 8
        imageView2.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]

        imageView1.snp.makeConstraints { make in
            make.top.leading.bottom.equalToSuperview()
            make.trailing.equalTo(containerView.snp.centerX).offset(-0.5)
        }

        imageView2.snp.makeConstraints { make in
            make.top.trailing.bottom.equalToSuperview()
            make.leading.equalTo(containerView.snp.centerX).offset(0.5)
        }

        addBlurIfLocked(photo1, over: imageView1, corners: [.layerMinXMinYCorner, .layerMinXMaxYCorner])
        addBlurIfLocked(photo2, over: imageView2, corners: [.layerMaxXMinYCorner, .layerMaxXMaxYCorner])
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

        addBlurIfLocked(cards[0], over: topImageView, corners: [.layerMinXMinYCorner, .layerMaxXMinYCorner])
        addBlurIfLocked(cards[1], over: bottomLeftImageView, corners: [.layerMinXMaxYCorner])
        addBlurIfLocked(cards[2], over: bottomRightImageView, corners: [.layerMaxXMaxYCorner])
    }

    // MARK: - 왼쪽1 + 오른쪽2 (가로형 셀, 3장)
    //  ┌──────┬──────┐
    //  │      │ img2 │
    //  │ img1 ├──────┤
    //  │      │ img3 │
    //  └──────┴──────┘

    private func layoutThreeLeftOneImages(cards: [CardCalendarItemDTO]) {
        guard cards.count >= 3 else { return }

        let leftImageView = createImageView()
        let topRightImageView = createImageView()
        let bottomRightImageView = createImageView()

        imageViews.append(contentsOf: [leftImageView, topRightImageView, bottomRightImageView])
        containerView.addSubview(leftImageView)
        containerView.addSubview(topRightImageView)
        containerView.addSubview(bottomRightImageView)

        ThumbnailCache.shared.loadThumbnail(for: cards[0].id, maxPixelSize: thumbnailPixelSize) { [weak leftImageView] image in
            leftImageView?.image = image
        }
        ThumbnailCache.shared.loadThumbnail(for: cards[1].id, maxPixelSize: thumbnailPixelSize) { [weak topRightImageView] image in
            topRightImageView?.image = image
        }
        ThumbnailCache.shared.loadThumbnail(for: cards[2].id, maxPixelSize: thumbnailPixelSize) { [weak bottomRightImageView] image in
            bottomRightImageView?.image = image
        }

        leftImageView.layer.cornerRadius = 8
        leftImageView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]

        topRightImageView.layer.cornerRadius = 8
        topRightImageView.layer.maskedCorners = [.layerMaxXMinYCorner]

        bottomRightImageView.layer.cornerRadius = 8
        bottomRightImageView.layer.maskedCorners = [.layerMaxXMaxYCorner]

        leftImageView.snp.makeConstraints { make in
            make.top.leading.bottom.equalToSuperview()
            make.trailing.equalTo(containerView.snp.centerX).offset(-0.5)
        }

        topRightImageView.snp.makeConstraints { make in
            make.top.trailing.equalToSuperview()
            make.leading.equalTo(containerView.snp.centerX).offset(0.5)
            make.bottom.equalTo(containerView.snp.centerY).offset(-0.5)
        }

        bottomRightImageView.snp.makeConstraints { make in
            make.bottom.trailing.equalToSuperview()
            make.leading.equalTo(containerView.snp.centerX).offset(0.5)
            make.top.equalTo(containerView.snp.centerY).offset(0.5)
        }

        addBlurIfLocked(cards[0], over: leftImageView, corners: [.layerMinXMinYCorner, .layerMinXMaxYCorner])
        addBlurIfLocked(cards[1], over: topRightImageView, corners: [.layerMaxXMinYCorner])
        addBlurIfLocked(cards[2], over: bottomRightImageView, corners: [.layerMaxXMaxYCorner])
    }

    // MARK: - 2×2 그리드 (4장)
    //  ┌──────┬──────┐
    //  │ img1 │ img2 │
    //  ├──────┼──────┤
    //  │ img3 │ img4 │
    //  └──────┴──────┘

    private func layoutFourGridImages(cards: [CardCalendarItemDTO]) {
        guard cards.count >= 4 else { return }

        let topLeft = createImageView()
        let topRight = createImageView()
        let bottomLeft = createImageView()
        let bottomRight = createImageView()

        let views = [topLeft, topRight, bottomLeft, bottomRight]
        imageViews.append(contentsOf: views)
        views.forEach { containerView.addSubview($0) }

        for (index, card) in cards.prefix(4).enumerated() {
            let imageView = views[index]
            ThumbnailCache.shared.loadThumbnail(for: card.id, maxPixelSize: thumbnailPixelSize) { [weak imageView] image in
                imageView?.image = image
            }
        }

        topLeft.layer.cornerRadius = 8
        topLeft.layer.maskedCorners = [.layerMinXMinYCorner]

        topRight.layer.cornerRadius = 8
        topRight.layer.maskedCorners = [.layerMaxXMinYCorner]

        bottomLeft.layer.cornerRadius = 8
        bottomLeft.layer.maskedCorners = [.layerMinXMaxYCorner]

        bottomRight.layer.cornerRadius = 8
        bottomRight.layer.maskedCorners = [.layerMaxXMaxYCorner]

        topLeft.snp.makeConstraints { make in
            make.top.leading.equalToSuperview()
            make.trailing.equalTo(containerView.snp.centerX).offset(-0.5)
            make.bottom.equalTo(containerView.snp.centerY).offset(-0.5)
        }

        topRight.snp.makeConstraints { make in
            make.top.trailing.equalToSuperview()
            make.leading.equalTo(containerView.snp.centerX).offset(0.5)
            make.bottom.equalTo(containerView.snp.centerY).offset(-0.5)
        }

        bottomLeft.snp.makeConstraints { make in
            make.bottom.leading.equalToSuperview()
            make.trailing.equalTo(containerView.snp.centerX).offset(-0.5)
            make.top.equalTo(containerView.snp.centerY).offset(0.5)
        }

        bottomRight.snp.makeConstraints { make in
            make.bottom.trailing.equalToSuperview()
            make.leading.equalTo(containerView.snp.centerX).offset(0.5)
            make.top.equalTo(containerView.snp.centerY).offset(0.5)
        }

        let corners: [CACornerMask] = [
            [.layerMinXMinYCorner],
            [.layerMaxXMinYCorner],
            [.layerMinXMaxYCorner],
            [.layerMaxXMaxYCorner]
        ]

        for (index, card) in cards.prefix(4).enumerated() {
            addBlurIfLocked(card, over: views[index], corners: corners[index])
        }
    }

    private func clearImageAndBlurViews() {
        imageViews.forEach { $0.removeFromSuperview() }
        imageViews.removeAll()
        blurViews.forEach { $0.removeFromSuperview() }
        blurViews.removeAll()
    }

    private func addBlurIfLocked(
        _ card: CardCalendarItemDTO,
        over imageView: UIImageView,
        corners: CACornerMask = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
    ) {
        guard card.isLocked else { return }
        let blurView = createBlurView()
        blurView.layer.cornerRadius = 8
        blurView.layer.maskedCorners = corners
        blurViews.append(blurView)
        containerView.addSubview(blurView)
        blurView.snp.makeConstraints { make in
            make.edges.equalTo(imageView)
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
        clearImageAndBlurViews()
        dayLabel.text = ""
        contentView.layer.borderWidth = 0
        isToday = false
        addButton.isHidden = true
        cachedSortedCards = []
        cachedLayoutDecision = nil
        cachedBoundsSize = .zero
    }
}
