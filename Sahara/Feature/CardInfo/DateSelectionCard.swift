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

final class DateSelectionCard: UIView {
    private let cardView: UIView = {
        let view = UIView()
        view.backgroundColor = ColorSystem.purpleGray20
        view.layer.cornerRadius = 12
        return view
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("card_info.date", comment: "")
        label.font = FontSystem.galmuriMono(size: 14)
        label.textColor = ColorSystem.black
        return label
    }()

    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "calendar")
        imageView.tintColor = ColorSystem.darkGray
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    let valueLabel: UILabel = {
        let label = UILabel()
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateStyle = .long
        label.text = formatter.string(from: Date())
        label.font = FontSystem.galmuriMono(size: 16)
        label.textColor = ColorSystem.darkGray
        return label
    }()

    let selectButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .clear
        return button
    }()

    private let disposeBag = DisposeBag()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureUI() {
        addSubview(cardView)
        cardView.addSubview(titleLabel)
        cardView.addSubview(valueLabel)
        cardView.addSubview(iconImageView)
        cardView.addSubview(selectButton)

        cardView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalTo(80)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(16)
        }

        iconImageView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.leading.equalToSuperview().inset(16)
            make.width.height.equalTo(20)
            make.bottom.equalToSuperview().inset(16)
        }

        valueLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconImageView.snp.trailing).offset(8)
            make.centerY.equalTo(iconImageView)
        }

        selectButton.snp.makeConstraints { make in
            make.edges.equalToSuperview()
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
