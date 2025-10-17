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

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "언어를 선택해주세요"
        label.font = FontSystem.galmuriMono(size: 24)
        label.textColor = ColorSystem.darkGray
        label.textAlignment = .center
        return label
    }()

    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.text = "Please select your language"
        label.font = FontSystem.galmuriMono(size: 14)
        label.textColor = ColorSystem.charcoal
        label.textAlignment = .center
        label.numberOfLines = 0
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

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        bind()
        setupInitialLanguage()
    }

    private func configureUI() {
        view.applyGradientWithDots(.pinkToBlue, dotSize: 5, spacing: 32, dotColor: ColorSystem.white)

        view.addSubview(titleLabel)
        view.addSubview(descriptionLabel)
        view.addSubview(tableView)

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(80)
            make.horizontalEdges.equalToSuperview().inset(20)
        }

        descriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(12)
            make.horizontalEdges.equalToSuperview().inset(20)
        }

        tableView.snp.makeConstraints { make in
            make.top.equalTo(descriptionLabel.snp.bottom).offset(40)
            make.horizontalEdges.equalToSuperview()
            make.height.equalTo(240)
        }
    }

    private func setupInitialLanguage() {
        let systemLanguage = LanguageManager.shared.systemLanguage

        if !LanguageManager.shared.isSupportedSystemLanguage {
            titleLabel.text = "Please select your language"
            descriptionLabel.text = ""
        } else {
            switch systemLanguage {
            case .korean:
                titleLabel.text = "언어를 선택해주세요"
                descriptionLabel.text = ""
            case .english:
                titleLabel.text = "Please select your language"
                descriptionLabel.text = ""
            case .japanese:
                titleLabel.text = "言語を選択してください"
                descriptionLabel.text = ""
            case .chinese:
                titleLabel.text = "请选择语言"
                descriptionLabel.text = ""
            }
        }
    }

    private func bind() {
        let languages = Observable.just(Language.allCases)

        languages
            .bind(to: tableView.rx.items(cellIdentifier: "LanguageCell")) { _, language, cell in
                cell.textLabel?.text = language.localizedDescription
                cell.textLabel?.font = FontSystem.galmuriMono(size: 16)
                cell.backgroundColor = .clear
                cell.selectionStyle = .none

                let systemLanguage = LanguageManager.shared.systemLanguage
                if language == systemLanguage {
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
                LanguageManager.shared.setLanguage(language)
                owner.onLanguageSelected?()
            }
            .disposed(by: disposeBag)
    }
}
