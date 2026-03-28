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

final class BiometricLockCard: BaseCard {
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("card_info.secret_description", comment: "")
        label.font = .typography(.body)
        label.textColor = .token(.textSecondary)
        return label
    }()

    let lockSwitch: UISwitch = {
        let switchControl = UISwitch()
        return switchControl
    }()

    private var viewModel: BiometricLockCardViewModel?
    private let disposeBag = DisposeBag()

    init() {
        super.init(title: NSLocalizedString("card_info.secret", comment: ""))
        configureContent()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureContent() {
        let container = UIView()
        container.addSubview(descriptionLabel)
        container.addSubview(lockSwitch)

        descriptionLabel.snp.makeConstraints { make in
            make.top.leading.bottom.equalToSuperview()
            make.trailing.equalTo(lockSwitch.snp.leading).offset(-12)
        }

        lockSwitch.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview()
        }

        addContentView(container)
    }

    func bind(initialIsLocked: Bool) -> BiometricLockCardViewModel.Output {
        let viewModel = BiometricLockCardViewModel(initialIsLocked: initialIsLocked)
        self.viewModel = viewModel

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
