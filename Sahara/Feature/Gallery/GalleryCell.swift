//
//  GalleryCell.swift
//  Sahara
//
//  Created by 금가경 on 9/29/25.
//

import UIKit

final class GalleryCell: UICollectionViewCell, IsIdentifiable {    
    private var imageView = UIImageView()
    
    private var dayLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .bold)
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureUI()
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    private func configureUI() {
        contentView.layer.borderWidth = 1.0
        contentView.layer.borderColor = UIColor.black.cgColor
        contentView.layer.masksToBounds = true
        
        addSubview(imageView)
        addSubview(dayLabel)
        
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        dayLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.leading.equalToSuperview().offset(20)
        }
    }
    
    func configure(with item: DayItem) {
        if let date = item.date {
            let day = Calendar.current.component(.day, from: date)
            dayLabel.text = "\(day)"
            imageView.image = item.photoMemos.first.flatMap { UIImage(data: $0.imageData) }
        } else {
            dayLabel.text = ""
            imageView.image = nil
        }
    }
}
