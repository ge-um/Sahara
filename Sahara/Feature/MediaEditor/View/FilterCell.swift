//
//  FilterCell.swift
//  Sahara
//
//  Created by 금가경 on 9/26/25.
//

import UIKit
import SnapKit

final class FilterCell: UICollectionViewCell {
    static let identifier = "FilterCell"

    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        return imageView
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .typography(.caption)
        label.textAlignment = .center
        label.textColor = .token(.textPrimary)
        return label
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
        contentView.addSubview(nameLabel)

        imageView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(90)
        }

        nameLabel.snp.makeConstraints { make in
            make.top.equalTo(imageView.snp.bottom).offset(4)
            make.horizontalEdges.equalToSuperview()
            make.bottom.equalToSuperview()
        }
    }

    func configure(with name: String, image: UIImage?, filter: CIFilter?, context: CIContext) {
        nameLabel.text = name

        guard let image = image else { return }

        if filter == nil {
            imageView.image = image
            return
        }

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let ciImage = CIImage(image: image),
                  let filter = filter else { return }

            filter.setValue(ciImage, forKey: kCIInputImageKey)

            guard let outputImage = filter.outputImage,
                  let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else { return }

            let filteredImage = UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)

            DispatchQueue.main.async {
                self?.imageView.image = filteredImage
            }
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        nameLabel.text = nil
    }
}
