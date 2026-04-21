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
        view.applyGlassCardStyle()
        return view
    }()

    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .typography(.label)
        label.textColor = .token(.textSecondary)
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
            make.top.equalToSuperview().inset(16)
            make.horizontalEdges.equalToSuperview().inset(20)
        }

        contentContainer.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.horizontalEdges.equalToSuperview().inset(20)
            make.bottom.equalToSuperview().inset(16)
        }
    }

    func addContentView(_ view: UIView) {
        contentContainer.addSubview(view)
        view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}
