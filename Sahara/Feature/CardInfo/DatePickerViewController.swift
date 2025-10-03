//
//  DatePickerViewController.swift
//  Sahara
//
//  Created by Claude on 10/3/25.
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit

final class DatePickerViewController: UIViewController {
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "날짜 선택"
        label.font = FontSystem.galmuriMono(size: 18)
        label.textColor = ColorSystem.labelSecondary
        label.textAlignment = .center
        return label
    }()

    private let datePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .date
        picker.preferredDatePickerStyle = .inline
        picker.locale = Locale(identifier: "ko_KR")
        return picker
    }()

    private let confirmButton: UIButton = {
        let button = UIButton()
        button.setTitle("확인", for: .normal)
        button.titleLabel?.font = FontSystem.galmuriMono(size: 14)
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.clipsToBounds = true
        button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 24, bottom: 12, right: 24)
        return button
    }()

    var onDateSelected: ((Date) -> Void)?
    private let disposeBag = DisposeBag()
    private let initialDate: Date

    init(initialDate: Date = Date()) {
        self.initialDate = initialDate
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        datePicker.date = initialDate
        configureUI()
        bind()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        confirmButton.applyGradient(.buttonPink)
    }

    private func configureUI() {
        view.backgroundColor = .systemBackground

        view.addSubview(titleLabel)
        view.addSubview(datePicker)
        view.addSubview(confirmButton)

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            make.horizontalEdges.equalToSuperview().inset(20)
        }

        datePicker.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(20)
            make.horizontalEdges.equalToSuperview().inset(20)
        }

        confirmButton.snp.makeConstraints { make in
            make.top.equalTo(datePicker.snp.bottom).offset(30)
            make.centerX.equalToSuperview()
            make.bottom.lessThanOrEqualTo(view.safeAreaLayoutGuide).offset(-20)
        }
    }

    private func bind() {
        confirmButton.rx.tap
            .bind(with: self) { owner, _ in
                owner.onDateSelected?(owner.datePicker.date)
                owner.dismiss(animated: true)
            }
            .disposed(by: disposeBag)
    }
}
