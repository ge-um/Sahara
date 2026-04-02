//
//  DatePickerViewController.swift
//  Sahara
//
//  Created by 금가경 on 10/3/25.
//

import UIKit
import SnapKit

final class DatePickerViewController: UIViewController {
    private let datePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .date
        picker.preferredDatePickerStyle = .inline
        picker.locale = Locale.current
        return picker
    }()

    var onDateSelected: ((Date) -> Void)?
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
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        onDateSelected?(datePicker.date)
    }

    private func configureUI() {
        view.backgroundColor = .systemBackground

        view.addSubview(datePicker)

        datePicker.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            make.horizontalEdges.equalToSuperview().inset(8)
            make.bottom.lessThanOrEqualTo(view.safeAreaLayoutGuide).offset(-20)
        }
    }
}
