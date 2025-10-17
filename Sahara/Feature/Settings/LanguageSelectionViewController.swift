//
//  LanguageSelectionViewController.swift
//  Sahara
//
//  Created by 금가경 on 10/17/25.
//

import RxCocoa
import RxSwift
import SnapKit
import UIKit

final class LanguageSelectionViewController: UIViewController {
    private let viewModel: LanguageSelectionViewModel
    private let disposeBag = DisposeBag()
    private let viewWillAppearRelay = PublishRelay<Void>()

    private let customNavigationBar = CustomNavigationBar()

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.backgroundColor = .clear
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "LanguageCell")
        tableView.rowHeight = 56
        tableView.separatorStyle = .none
        return tableView
    }()

    init(viewModel: LanguageSelectionViewModel = LanguageSelectionViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        setupCustomNavigationBar()
        configureUI()
        bind()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewWillAppearRelay.accept(())
    }

    private func setupCustomNavigationBar() {
        customNavigationBar.configure(title: NSLocalizedString("language.title", comment: ""))
        customNavigationBar.onLeftButtonTapped = { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }
    }

    private func configureUI() {
        view.applyGradientWithDots(.pinkToBlue, dotSize: 5, spacing: 32, dotColor: ColorSystem.white)

        view.addSubview(customNavigationBar)
        view.addSubview(tableView)

        customNavigationBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.horizontalEdges.equalToSuperview()
            make.height.equalTo(54)
        }

        tableView.snp.makeConstraints { make in
            make.top.equalTo(customNavigationBar.snp.bottom)
            make.horizontalEdges.bottom.equalTo(view.safeAreaLayoutGuide)
        }
    }

    private func bind() {
        let languageSelected = tableView.rx.modelSelected(Language.self).asObservable()

        let input = LanguageSelectionViewModel.Input(
            viewWillAppear: viewWillAppearRelay.asObservable(),
            languageSelected: languageSelected
        )

        let output = viewModel.transform(input: input)

        output.languages
            .drive(tableView.rx.items(cellIdentifier: "LanguageCell")) { _, language, cell in
                cell.textLabel?.text = language.localizedDescription
                cell.textLabel?.font = FontSystem.galmuriMono(size: 16)
                cell.backgroundColor = .clear
                cell.selectionStyle = .none

                let currentLanguage = LanguageManager.shared.currentLanguage
                if language == currentLanguage {
                    cell.accessoryType = .checkmark
                    cell.tintColor = ColorSystem.systemBlue
                } else {
                    cell.accessoryType = .none
                }
            }
            .disposed(by: disposeBag)

        output.languageChanged
            .drive(with: self) { owner, _ in
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .disposed(by: disposeBag)
    }
}
