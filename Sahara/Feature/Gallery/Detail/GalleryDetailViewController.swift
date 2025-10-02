//
//  GalleryDetailViewController.swift
//  Sahara
//
//  Created by 금가경 on 9/29/25.
//

import SnapKit
import UIKit
import RealmSwift

final class GalleryDetailViewController: UIViewController {
    private let date: Date
    private var photoMemos: Results<Memo>?
    private let realm = try! Realm()

    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = 80
        return tableView
    }()

    init(date: Date) {
        self.date = date
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .none)
        configureUI()
        fetchData()
    }

    private func configureUI() {
        view.backgroundColor = .white

        view.addSubview(tableView)

        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func fetchData() {
        let startOfDay = Calendar.current.startOfDay(for: date)
        guard let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay) else { return }

        photoMemos = realm.objects(Memo.self)
            .filter("createdDate >= %@ AND createdDate < %@", startOfDay, endOfDay)
            .sorted(byKeyPath: "createdDate", ascending: true)

        tableView.reloadData()
    }
}

extension GalleryDetailViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return photoMemos?.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        if let memo = photoMemos?[indexPath.row] {
            cell.imageView?.image = UIImage(data: memo.editedImageData)
            cell.textLabel?.text = memo.memo ?? "(메모 없음)"
        }
        return cell
    }
}

extension GalleryDetailViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard let photoMemo = photoMemos?[indexPath.row] else { return }

        let detailVC = PhotoDetailViewController(photoMemoId: photoMemo.id)
        detailVC.modalPresentationStyle = .fullScreen
        present(detailVC, animated: true)
    }
}
