//
//  AlbumListOverlayView.swift
//  Sahara
//
//  Created by 금가경 on 3/27/26.
//

import SnapKit
import UIKit

final class AlbumListOverlayView: UIView {
    let tableView: UITableView = {
        let tv = UITableView()
        tv.backgroundColor = .systemBackground
        tv.rowHeight = 60
        tv.separatorStyle = .none
        tv.register(AlbumListCell.self, forCellReuseIdentifier: AlbumListCell.identifier)
        tv.showsVerticalScrollIndicator = false
        return tv
    }()

    private static let maxHeight: CGFloat = 400

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .systemBackground
        layer.cornerRadius = 12
        layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        clipsToBounds = true

        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.15
        layer.shadowOffset = CGSize(width: 0, height: 4)
        layer.shadowRadius = 8
        layer.masksToBounds = false

        addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.lessThanOrEqualTo(AlbumListOverlayView.maxHeight)
        }
    }

    func updateHeight(for albumCount: Int) {
        let contentHeight = CGFloat(albumCount) * 60
        let height = min(contentHeight, AlbumListOverlayView.maxHeight)
        tableView.snp.updateConstraints { make in
            make.height.lessThanOrEqualTo(height)
        }
    }
}
