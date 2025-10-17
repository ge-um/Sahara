//
//  ListItemView.swift
//  Sahara
//
//  Created by 금가경 on 10/11/25.
//

import SnapKit
import UIKit

final class ListItemView: UIView {
    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.alignment = .leading
        return stackView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = ColorSystem.lavender20
        layer.cornerRadius = 12
        clipsToBounds = true

        addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(16)
        }
    }

    func configure(items: [String]) {
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        if items.isEmpty {
            let label = UILabel()
            label.text = NSLocalizedString("stats.no_data", comment: "")
            label.font = FontSystem.galmuriMono(size: 12)
            label.textColor = UIColor(hex: "#666666")
            stackView.addArrangedSubview(label)
        } else {
            for item in items {
                let label = UILabel()
                label.text = "• \(item)"
                label.font = FontSystem.galmuriMono(size: 12)
                label.textColor = .black
                stackView.addArrangedSubview(label)
            }
        }
    }
}

