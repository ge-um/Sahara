//
//  BiometricLockCard.swift
//  Sahara
//
//  Created by 금가경 on 10/12/25.
//

import RxCocoa
import RxSwift
import SnapKit
import UIKit

final class BiometricLockCard: UIView {
    private let cardView: UIView = {
        let view = UIView()
        view.backgroundColor = ColorSystem.cardBackground
        view.layer.cornerRadius = 12
        return view
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("card_info.secret", comment: "")
        label.font = FontSystem.galmuriMono(size: 14)
        label.textColor = ColorSystem.labelTitle
        return label
    }()

    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("card_info.secret_description", comment: "")
        label.font = FontSystem.galmuriMono(size: 12)
        label.textColor = ColorSystem.labelPrimary
        return label
    }()

    let lockSwitch: UISwitch = {
        let switchControl = UISwitch()
        return switchControl
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
        cardView.addSubview(descriptionLabel)
        cardView.addSubview(lockSwitch)

        cardView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        titleLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(16)
        }

        descriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.leading.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().inset(16)
        }

        lockSwitch.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().inset(16)
        }
    }

    func bind(viewModel: BiometricLockCardViewModel) -> BiometricLockCardViewModel.Output {
        let input = BiometricLockCardViewModel.Input(
            switchToggled: lockSwitch.rx.isOn.asObservable()
        )

        let output = viewModel.transform(input: input)

        output.switchValue
            .drive(lockSwitch.rx.isOn)
            .disposed(by: disposeBag)

        return output
    }
}
