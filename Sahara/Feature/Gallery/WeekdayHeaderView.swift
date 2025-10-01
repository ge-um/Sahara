//
//  WeekdayHeaderView.swift
//  Sahara
//
//  Created by 금가경 on 9/30/25.
//

import UIKit

final class WeekdayHeaderView: UICollectionReusableView, IsIdentifiable {
    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        return stack
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        backgroundColor = .systemGray6
        addSubview(stackView)

        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        let weekdayKeys = ["weekday.sunday", "weekday.monday", "weekday.tuesday", "weekday.wednesday", "weekday.thursday", "weekday.friday", "weekday.saturday"]
        weekdayKeys.enumerated().forEach { index, key in
            let label = UILabel()
            label.text = NSLocalizedString(key, comment: "")
            label.textAlignment = .center
            label.font = .systemFont(ofSize: 14, weight: .semibold)
            label.textColor = index == 0 ? .systemRed : (index == 6 ? .systemBlue : .label)
            stackView.addArrangedSubview(label)
        }
    }
}
