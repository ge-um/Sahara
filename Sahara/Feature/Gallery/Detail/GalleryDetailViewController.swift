//
//  GalleryDetailViewController.swift
//  Sahara
//
//  Created by 금가경 on 9/29/25.
//

import RxCocoa
import RxSwift
import SnapKit
import UIKit

final class GalleryDetailViewController: UIViewController {
    private let viewModel: GalleryDetailViewModel
    private let disposeBag = DisposeBag()
    private let viewDidLoadTrigger = PublishRelay<Void>()

    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.rowHeight = 80
        return tableView
    }()

    init(date: Date) {
        self.viewModel = GalleryDetailViewModel(date: date)
        super.init(nibName: nil, bundle: nil)
        title = DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .none)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        bind()
        viewDidLoadTrigger.accept(())
    }

    private func configureUI() {
        view.backgroundColor = .white

        view.addSubview(tableView)

        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func bind() {
        let input = GalleryDetailViewModel.Input(
            viewDidLoad: viewDidLoadTrigger.asObservable(),
            itemSelected: tableView.rx.itemSelected.asObservable()
        )

        let output = viewModel.transform(input: input)

        output.memos
            .drive(tableView.rx.items(cellIdentifier: "Cell")) { _, memo, cell in
                cell.imageView?.image = UIImage(data: memo.editedImageData)
                cell.textLabel?.text = memo.memo ?? "(메모 없음)"
            }
            .disposed(by: disposeBag)

        output.navigateToDetail
            .drive(with: self) { owner, photoMemoId in
                let detailVC = PhotoDetailViewController(photoMemoId: photoMemoId)
                detailVC.modalPresentationStyle = .fullScreen
                owner.present(detailVC, animated: true)
            }
            .disposed(by: disposeBag)

        tableView.rx.itemSelected
            .bind(with: self) { owner, indexPath in
                owner.tableView.deselectRow(at: indexPath, animated: true)
            }
            .disposed(by: disposeBag)
    }
}
