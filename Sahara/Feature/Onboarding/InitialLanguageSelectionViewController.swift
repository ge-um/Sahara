//
//  InitialLanguageSelectionViewController.swift
//  Sahara
//
//  Created by 금가경 on 10/18/25.
//

import RxCocoa
import RxSwift
import SnapKit
import UIKit

final class InitialLanguageSelectionViewController: UIViewController {
    private let disposeBag = DisposeBag()
    var onLanguageSelected: (() -> Void)?

    private var selectedLanguage: Language

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = FontSystem.galmuriMono(size: 24)
        label.textColor = ColorSystem.darkGray
        label.textAlignment = .center
        return label
    }()

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.backgroundColor = .clear
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "LanguageCell")
        tableView.rowHeight = 56
        tableView.separatorStyle = .none
        tableView.isScrollEnabled = false
        return tableView
    }()

    private let confirmButton: UIButton = {
        let button = UIButton()
        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = ColorSystem.skyBlue
        config.baseForegroundColor = ColorSystem.white
        config.cornerStyle = .medium
        config.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 32, bottom: 16, trailing: 32)

        var titleAttr = AttributeContainer()
        titleAttr.font = FontSystem.galmuriMono(size: 16)
        config.attributedTitle = AttributedString("", attributes: titleAttr)

        button.configuration = config
        button.layer.cornerRadius = 8
        button.clipsToBounds = true
        return button
    }()

    init() {
        self.selectedLanguage = LanguageManager.shared.systemLanguage
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        bind()
        updateLanguage(selectedLanguage)
    }

    private func configureUI() {
        view.applyGradientWithDots(.pinkToBlue, dotSize: 5, spacing: 32, dotColor: ColorSystem.white)

        view.addSubview(titleLabel)
        view.addSubview(tableView)
        view.addSubview(confirmButton)

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(80)
            make.horizontalEdges.equalToSuperview().inset(20)
        }

        tableView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(40)
            make.horizontalEdges.equalToSuperview()
            make.height.equalTo(240)
        }

        confirmButton.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-40)
            make.centerX.equalToSuperview()
        }
    }

    private func updateLanguage(_ language: Language) {
        switch language {
        case .korean:
            titleLabel.text = "언어를 선택해주세요"
            updateButtonTitle("확인")
        case .english:
            titleLabel.text = "Please select your language"
            updateButtonTitle("Confirm")
        case .japanese:
            titleLabel.text = "言語を選択してください"
            updateButtonTitle("確認")
        case .chinese:
            titleLabel.text = "请选择语言"
            updateButtonTitle("确认")
        }
    }

    private func updateButtonTitle(_ title: String) {
        var config = confirmButton.configuration
        var titleAttr = AttributeContainer()
        titleAttr.font = FontSystem.galmuriMono(size: 16)
        config?.attributedTitle = AttributedString(title, attributes: titleAttr)
        confirmButton.configuration = config
    }

    private func bind() {
        let languages = Observable.just(Language.allCases)

        languages
            .bind(to: tableView.rx.items(cellIdentifier: "LanguageCell")) { [weak self] _, language, cell in
                guard let self = self else { return }
                cell.textLabel?.text = language.localizedDescription
                cell.textLabel?.font = FontSystem.galmuriMono(size: 16)
                cell.backgroundColor = .clear
                cell.selectionStyle = .none

                if language == self.selectedLanguage {
                    cell.accessoryType = .checkmark
                    cell.tintColor = ColorSystem.systemBlue
                } else {
                    cell.accessoryType = .none
                }
            }
            .disposed(by: disposeBag)

        tableView.rx.modelSelected(Language.self)
            .withUnretained(self)
            .bind { owner, language in
                owner.selectedLanguage = language
                owner.updateLanguage(language)
                owner.tableView.reloadData()
            }
            .disposed(by: disposeBag)

        confirmButton.rx.tap
            .withUnretained(self)
            .bind { owner, _ in
                LanguageManager.shared.setLanguage(owner.selectedLanguage)
                owner.onLanguageSelected?()
            }
            .disposed(by: disposeBag)
    }
}
