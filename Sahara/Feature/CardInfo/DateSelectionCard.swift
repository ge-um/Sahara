//
//  DateSelectionCard.swift
//  Sahara
//
//  Created by 금가경 on 10/12/25.
//

import RxCocoa
import RxSwift
import SnapKit
import UIKit

enum DateSource {
    case exif
    case userPicked
    case initial
}

final class DateSelectionCard: BaseCard {
    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "calendar")
        imageView.tintColor = .token(.textSecondary)
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    let valueLabel: UILabel = {
        let label = UILabel()
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateStyle = .long
        label.text = formatter.string(from: Date())
        label.font = DesignToken.Typography.caption.numericFont
        label.textColor = .token(.textSecondary)
        return label
    }()

    let selectButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .clear
        return button
    }()

    private let disposeBag = DisposeBag()

    init() {
        super.init(title: NSLocalizedString("card_info.date", comment: ""))
        configureContent()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureContent() {
        let container = UIView()
        container.addSubview(iconImageView)
        container.addSubview(valueLabel)
        container.addSubview(selectButton)

        iconImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
            make.width.height.equalTo(16)
        }

        valueLabel.snp.makeConstraints { make in
            make.centerY.equalTo(iconImageView)
            make.leading.equalTo(iconImageView.snp.trailing).offset(8)
            make.trailing.lessThanOrEqualToSuperview()
            make.bottom.lessThanOrEqualToSuperview()
        }

        selectButton.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        addContentView(container)
    }

    func bind(date: Driver<(date: Date, source: DateSource)>) {
        date
            .drive(with: self) { owner, value in
                let formatter = DateFormatter()
                formatter.locale = Locale.current
                formatter.dateStyle = .long
                owner.valueLabel.text = formatter.string(from: value.date)

                switch value.source {
                case .exif, .initial:
                    owner.valueLabel.textColor = .token(.textTertiary)
                case .userPicked:
                    owner.valueLabel.textColor = .token(.textSecondary)
                }
            }
            .disposed(by: disposeBag)
    }
}
