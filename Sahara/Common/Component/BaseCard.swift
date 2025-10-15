//
//  BaseCard.swift
//  Sahara
//
//  Created by 금가경 on 10/15/25.
//

import SnapKit
import UIKit

class BaseCard: UIView {
    let cardView: UIView = {
        let view = UIView()
        view.backgroundColor = ColorSystem.purpleGray20
        view.layer.cornerRadius = 12
        return view
    }()

    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = FontSystem.galmuriMono(size: 14)
        label.textColor = ColorSystem.black
        return label
    }()

    let contentContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()

    init(title: String) {
        super.init(frame: .zero)
        titleLabel.text = title
        configureBaseUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureBaseUI() {
        addSubview(cardView)
        cardView.addSubview(titleLabel)
        cardView.addSubview(contentContainer)

        cardView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        titleLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(16)
        }

        contentContainer.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(12)
            make.horizontalEdges.bottom.equalToSuperview()
        }
    }

    func addContentView(_ view: UIView, insets: UIEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 16, right: 16)) {
        contentContainer.addSubview(view)
        view.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(insets)
        }
    }
}
