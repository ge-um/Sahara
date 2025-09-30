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
        
        let weekdays = ["일", "월", "화", "수", "목", "금", "토"]
        weekdays.forEach { day in
            let label = UILabel()
            label.text = day
            label.textAlignment = .center
            label.font = .systemFont(ofSize: 14, weight: .semibold)
            label.textColor = day == "일" ? .systemRed : (day == "토" ? .systemBlue : .label)
            stackView.addArrangedSubview(label)
        }
    }
}
