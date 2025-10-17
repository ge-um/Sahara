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

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Please select one of the supported languages"
        label.font = FontSystem.galmuriMono(size: 20)
        label.textColor = ColorSystem.darkGray
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

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        bind()
    }

    private func configureUI() {
        view.applyGradientWithDots(.pinkToBlue, dotSize: 5, spacing: 32, dotColor: ColorSystem.white)

        view.addSubview(titleLabel)
        view.addSubview(tableView)

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(80)
            make.horizontalEdges.equalToSuperview().inset(20)
        }

        tableView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(40)
            make.horizontalEdges.equalToSuperview()
            make.height.equalTo(240)
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
                cell.accessoryType = .disclosureIndicator
                cell.tintColor = ColorSystem.systemBlue
            }
            .disposed(by: disposeBag)

        tableView.rx.modelSelected(Language.self)
            .withUnretained(self)
            .bind { owner, _ in
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .disposed(by: disposeBag)
    }
}
