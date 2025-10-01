//
//  GalleryCell.swift
//  Sahara
//
//  Created by 금가경 on 9/29/25.
//

import SnapKit
import UIKit

final class GalleryCell: UICollectionViewCell, IsIdentifiable {
    private let containerView = UIView()

    private var dayLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .bold)
        return label
    }()

    private var imageViews: [UIImageView] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func configureUI() {
        contentView.layer.borderWidth = 1.0
        contentView.layer.borderColor = UIColor.systemGray4.cgColor
        contentView.layer.masksToBounds = true

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

            let photoCount = item.photoMemos.count

            if photoCount == 0 {
                // 사진 없음
                containerView.backgroundColor = .white
            } else if photoCount == 1 {
                // 1개: 전체 채움
                layoutSingleImage(item.photoMemos[0])
            } else if photoCount == 2 {
                // 2개: 가로로 나란히
                layoutTwoImages(item.photoMemos[0], item.photoMemos[1])
            } else {
                // 3개 이상: 1단에 1개, 2단에 2개
                layoutMultipleImages(photoMemos: Array(item.photoMemos.prefix(3)))
            }
        } else {
            dayLabel.text = ""
            containerView.backgroundColor = .white
        }
    }

    private func layoutSingleImage(_ photoMemo: PhotoMemo) {
        let imageView = createImageView()
        imageViews.append(imageView)
        containerView.addSubview(imageView)

        imageView.image = UIImage(data: photoMemo.imageData)
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func layoutTwoImages(_ photo1: PhotoMemo, _ photo2: PhotoMemo) {
        let imageView1 = createImageView()
        let imageView2 = createImageView()

        imageViews.append(contentsOf: [imageView1, imageView2])
        containerView.addSubview(imageView1)
        containerView.addSubview(imageView2)

        imageView1.image = UIImage(data: photo1.imageData)
        imageView2.image = UIImage(data: photo2.imageData)

        imageView1.snp.makeConstraints { make in
            make.top.leading.bottom.equalToSuperview()
            make.trailing.equalTo(containerView.snp.centerX).offset(-0.5)
        }

        imageView2.snp.makeConstraints { make in
            make.top.trailing.bottom.equalToSuperview()
            make.leading.equalTo(containerView.snp.centerX).offset(0.5)
        }
    }

    private func layoutMultipleImages(photoMemos: [PhotoMemo]) {
        guard photoMemos.count >= 3 else { return }

        let topImageView = createImageView()
        let bottomLeftImageView = createImageView()
        let bottomRightImageView = createImageView()

        imageViews.append(contentsOf: [topImageView, bottomLeftImageView, bottomRightImageView])
        containerView.addSubview(topImageView)
        containerView.addSubview(bottomLeftImageView)
        containerView.addSubview(bottomRightImageView)

        topImageView.image = UIImage(data: photoMemos[0].imageData)
        bottomLeftImageView.image = UIImage(data: photoMemos[1].imageData)
        bottomRightImageView.image = UIImage(data: photoMemos[2].imageData)

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
