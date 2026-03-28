//
//  CalendarHeaderView.swift
//  Sahara
//
//  Created by 금가경 on 10/2/25.
//

import UIKit
import SnapKit

final class CalendarHeaderView: UICollectionReusableView {
    static let identifier = "CalendarHeaderView"

    private let monthLabel: UILabel = {
        let label = UILabel()
        label.font = DesignToken.Typography.caption.numericFont
        label.textColor = .token(.textPrimary)
        label.textAlignment = .left
        return label
    }()

    private let previousMonthButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .white
        button.layer.cornerRadius = 14
        button.clipsToBounds = true
        button.setTitle("<", for: .normal)
        button.setTitleColor(.token(.navigationText), for: .normal)
        button.titleLabel?.font = .typography(.body)
        return button
    }()

    private let nextMonthButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .white
        button.layer.cornerRadius = 14
        button.clipsToBounds = true
        button.setTitle(">", for: .normal)
        button.setTitleColor(.token(.navigationText), for: .normal)
        button.titleLabel?.font = .typography(.body)
        return button
    }()

    private let weekdayStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        return stack
    }()

    var onPreviousMonthTapped: (() -> Void)?
    var onNextMonthTapped: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        setupActions()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        backgroundColor = .clear

        addSubview(monthLabel)
        addSubview(previousMonthButton)
        addSubview(nextMonthButton)
        addSubview(weekdayStackView)

        nextMonthButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.trailing.equalToSuperview().offset(-20)
            make.size.equalTo(28)
        }

        previousMonthButton.snp.makeConstraints { make in
            make.centerY.equalTo(nextMonthButton)
            make.trailing.equalTo(nextMonthButton.snp.leading).offset(-8)
            make.size.equalTo(28)
        }

        monthLabel.snp.makeConstraints { make in
            make.centerY.equalTo(nextMonthButton)
            make.leading.equalToSuperview().offset(20)
        }

        weekdayStackView.snp.makeConstraints { make in
            make.top.equalTo(monthLabel.snp.bottom).offset(12)
            make.horizontalEdges.equalToSuperview()
            make.bottom.equalToSuperview()
        }

        setupWeekdayLabels()
    }

    private func setupWeekdayLabels() {
        let weekdayKeys = ["weekday.sunday", "weekday.monday", "weekday.tuesday", "weekday.wednesday", "weekday.thursday", "weekday.friday", "weekday.saturday"]
        weekdayKeys.enumerated().forEach { index, key in
            let label = UILabel()
            let weekdayText = NSLocalizedString(key, comment: "")

            // Galmuri14, font size 10, letter spacing -6%
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.firstLineHeadIndent = 8

            let attributedString = weekdayText.attributedString(
                font: UIFont.typography(.small),
                letterSpacing: -6,
                color: index == 0 ? .systemRed : (index == 6 ? .systemBlue : .label)
            )
            let mutable = NSMutableAttributedString(attributedString: attributedString)
            mutable.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: mutable.length))
            label.attributedText = mutable
            label.textAlignment = .left
            weekdayStackView.addArrangedSubview(label)
        }
    }

    private func setupActions() {
        previousMonthButton.addTarget(self, action: #selector(previousMonthButtonTapped), for: .touchUpInside)
        nextMonthButton.addTarget(self, action: #selector(nextMonthButtonTapped), for: .touchUpInside)
    }

    @objc private func previousMonthButtonTapped() {
        onPreviousMonthTapped?()
    }

    @objc private func nextMonthButtonTapped() {
        onNextMonthTapped?()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        previousMonthButton.applyGradient(.tabBar, removeExisting: true)
        nextMonthButton.applyGradient(.tabBar, removeExisting: true)
    }

    func configure(monthTitle: String) {
        monthLabel.text = monthTitle
    }
}
