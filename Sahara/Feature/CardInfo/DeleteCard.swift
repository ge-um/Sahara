//
//  DeleteCard.swift
//  Sahara
//
//  Created by 금가경 on 10/12/25.
//

import RxCocoa
import RxSwift
import SnapKit
import UIKit

final class DeleteCard: BaseCard {
    let deleteButton: UIButton = {
        let button = UIButton()
        var config = UIButton.Configuration.filled()
        config.title = NSLocalizedString("card_info.delete_button", comment: "")
        config.baseBackgroundColor = .systemRed
        config.baseForegroundColor = .white
        config.cornerStyle = .medium
        config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)

        var titleAttr = AttributeContainer()
        titleAttr.font = FontSystem.galmuriMono(size: 14)
        config.attributedTitle = AttributedString(config.title ?? "", attributes: titleAttr)

        button.configuration = config
        button.layer.cornerRadius = 8
        button.clipsToBounds = true
        return button
    }()

    init() {
        super.init(title: NSLocalizedString("card_info.delete", comment: ""))
        isHidden = true
        configureContent()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureContent() {
        deleteButton.snp.makeConstraints { make in
            make.height.equalTo(44)
        }
        addContentView(deleteButton)
    }
}
