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

final class DateSelectionCard: BaseCard {
    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "calendar")
        imageView.tintColor = .token(.iconTint)
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    let valueLabel: UILabel = {
        let label = UILabel()
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateStyle = .long
        label.text = formatter.string(from: Date())
        label.font = FontSystem.galmuriMono(size: 14)
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
            make.top.leading.equalToSuperview()
            make.width.height.equalTo(20)
        }

        valueLabel.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.equalTo(iconImageView.snp.trailing).offset(8)
            make.trailing.lessThanOrEqualToSuperview()
            make.centerY.equalTo(iconImageView)
        }

        selectButton.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        addContentView(container)

        cardView.snp.makeConstraints { make in
            make.height.equalTo(90)
        }
    }

    func bind(date: Driver<Date>) {
        date
            .drive(with: self) { owner, date in
                let formatter = DateFormatter()
                formatter.locale = Locale.current
                formatter.dateStyle = .long
                owner.valueLabel.text = formatter.string(from: date)
            }
            .disposed(by: disposeBag)
    }
}
