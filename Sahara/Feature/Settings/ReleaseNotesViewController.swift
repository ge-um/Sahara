//
//  ReleaseNotesViewController.swift
//  Sahara
//
//  Created by 금가경 on 10/12/25.
//

import RxCocoa
import RxDataSources
import RxSwift
import SnapKit
import UIKit

final class ReleaseNotesViewController: UIViewController {
    private let viewModel: ReleaseNotesViewModel
    private let disposeBag = DisposeBag()
    private let viewWillAppearRelay = PublishRelay<Void>()

    private let customNavigationBar = CustomNavigationBar()

    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.register(ReleaseNoteCell.self, forCellReuseIdentifier: ReleaseNoteCell.identifier)
        return tableView
    }()

    init(viewModel: ReleaseNotesViewModel = ReleaseNotesViewModel()) {
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
        customNavigationBar.configure(title: NSLocalizedString("release_notes.title", comment: ""))

        if navigationController != nil && presentingViewController == nil {
            customNavigationBar.setLeftButtonImage(UIImage(named: "chevronLeft"))
            customNavigationBar.onLeftButtonTapped = { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            }
        } else {
            customNavigationBar.setLeftButtonImage(UIImage(systemName: "xmark"))
            customNavigationBar.onLeftButtonTapped = { [weak self] in
                self?.dismiss(animated: true)
            }
        }
    }

    private func configureUI() {
        view.applyGradientWithDots(.pinkBlue, dotSize: 5, spacing: 32, dotColor: ColorSystem.white)

        view.addSubview(customNavigationBar)
        view.addSubview(tableView)

        customNavigationBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.horizontalEdges.equalToSuperview()
            make.height.equalTo(54)
        }

        tableView.snp.makeConstraints { make in
            make.top.equalTo(customNavigationBar.snp.bottom).offset(20)
            make.horizontalEdges.equalToSuperview().inset(20)
            make.bottom.equalTo(view.safeAreaLayoutGuide)
        }
    }

    private func bind() {
        let input = ReleaseNotesViewModel.Input(
            viewWillAppear: viewWillAppearRelay.asObservable()
        )

        let output = viewModel.transform(input: input)

        let dataSource = RxTableViewSectionedReloadDataSource<ReleaseNoteSection>(
            configureCell: { _, tableView, indexPath, item in
                guard let cell = tableView.dequeueReusableCell(
                    withIdentifier: ReleaseNoteCell.identifier,
                    for: indexPath
                ) as? ReleaseNoteCell else {
                    return UITableViewCell()
                }
                cell.configure(with: item)
                return cell
            }
        )

        output.releaseNotes
            .map { [ReleaseNoteSection(items: $0)] }
            .drive(tableView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)

        tableView.rx.setDelegate(self)
            .disposed(by: disposeBag)
    }
}

extension ReleaseNotesViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
}

struct ReleaseNoteSection {
    var items: [ReleaseNote]
}

extension ReleaseNoteSection: SectionModelType {
    typealias Item = ReleaseNote

    init(original: ReleaseNoteSection, items: [ReleaseNote]) {
        self = original
        self.items = items
    }
}
