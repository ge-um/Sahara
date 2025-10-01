//
//  ThemeGalleryViewController.swift
//  Sahara
//
//  Created by Claude on 10/1/25.
//

import RealmSwift
import SnapKit
import UIKit
import Vision

final class ThemeGalleryViewController: UIViewController {
    private let realm = try! Realm()
    private var themeGroups: [ThemeGroup] = []

    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(ThemeCell.self, forCellReuseIdentifier: ThemeCell.identifier)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = 100
        return tableView
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        return indicator
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        analyzePhotos()
    }

    private func configureUI() {
        view.backgroundColor = .systemBackground

        view.addSubview(tableView)
        view.addSubview(activityIndicator)

        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        activityIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }

    private func analyzePhotos() {
        activityIndicator.startAnimating()

        let photoMemos = self.realm.objects(PhotoMemo.self)
        var categoryDict: [ThemeCategory: [PhotoMemo]] = [:]
        
        for photoMemo in photoMemos {
            guard let image = UIImage(data: photoMemo.imageData),
                  let cgImage = image.cgImage else { continue }
            
            let category = self.classifyImage(cgImage)
            categoryDict[category, default: []].append(photoMemo)
        }
        
        let groups = categoryDict.map { ThemeGroup(category: $0.key, photoMemos: $0.value) }
            .sorted { $0.category.rawValue < $1.category.rawValue }
        
        themeGroups = groups
        tableView.reloadData()
        activityIndicator.stopAnimating()
    }

    private func classifyImage(_ cgImage: CGImage) -> ThemeCategory {
        let request = VNClassifyImageRequest()

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([request])

            if let observations = request.results as? [VNClassificationObservation] {
                let topLabels = observations.prefix(5).map { $0.identifier }
                return ThemeCategory.category(for: topLabels)
            }
        } catch {
            print("Vision error: \(error)")
        }

        return .others
    }
}

extension ThemeGalleryViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return themeGroups.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: ThemeCell.identifier,
            for: indexPath
        ) as? ThemeCell else {
            return UITableViewCell()
        }

        let group = themeGroups[indexPath.row]
        cell.configure(with: group)
        return cell
    }
}

extension ThemeGalleryViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let group = themeGroups[indexPath.row]
        let galleryVC = MapPhotoGalleryViewController(photoMemos: group.photoMemos)
        let nav = UINavigationController(rootViewController: galleryVC)
        present(nav, animated: true)
    }
}

final class ThemeCell: UITableViewCell {
    static let identifier = "ThemeCell"

    private let thumbnailImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        imageView.backgroundColor = .systemGray6
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        return label
    }()

    private let countLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureUI() {
        contentView.addSubview(thumbnailImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(countLabel)

        thumbnailImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(80)
        }

        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(thumbnailImageView.snp.trailing).offset(16)
            make.top.equalTo(thumbnailImageView).offset(10)
            make.trailing.equalToSuperview().inset(16)
        }

        countLabel.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.trailing.equalToSuperview().inset(16)
        }
    }

    func configure(with group: ThemeGroup) {
        titleLabel.text = group.category.rawValue
        countLabel.text = "\(group.photoMemos.count)개의 사진"

        if let firstPhoto = group.photoMemos.first,
           let image = UIImage(data: firstPhoto.imageData) {
            thumbnailImageView.image = image
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        thumbnailImageView.image = nil
        titleLabel.text = nil
        countLabel.text = nil
    }
}
