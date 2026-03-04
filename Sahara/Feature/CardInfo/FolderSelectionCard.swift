//
//  FolderSelectionCard.swift
//  Sahara
//
//  Created by 금가경 on 10/13/25.
//

import RealmSwift
import RxCocoa
import RxSwift
import SnapKit
import UIKit

final class FolderSelectionCard: BaseCard {
    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "folder")
        imageView.tintColor = ColorSystem.darkGray
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    let textField: UITextField = {
        let textField = UITextField()
        textField.placeholder = NSLocalizedString("folder.default", comment: "")
        textField.font = FontSystem.galmuriMono(size: 14)
        textField.textColor = ColorSystem.darkGray
        textField.returnKeyType = .done
        return textField
    }()

    private let tagScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsHorizontalScrollIndicator = false
        return scrollView
    }()

    private let tagStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 4
        return stackView
    }()

    private let disposeBag = DisposeBag()
    let selectedFolderRelay = BehaviorRelay<String?>(value: nil)

    init() {
        super.init(title: NSLocalizedString("card_info.folder", comment: ""))
        configureContent()
        setupBinding()
        loadExistingFolders()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureContent() {
        let container = UIView()
        container.addSubview(iconImageView)
        container.addSubview(textField)
        container.addSubview(tagScrollView)
        tagScrollView.addSubview(tagStackView)

        iconImageView.snp.makeConstraints { make in
            make.top.leading.equalToSuperview()
            make.width.height.equalTo(20)
        }

        textField.snp.makeConstraints { make in
            make.leading.equalTo(iconImageView.snp.trailing).offset(8)
            make.centerY.equalTo(iconImageView)
            make.trailing.equalToSuperview()
        }

        tagScrollView.snp.makeConstraints { make in
            make.top.equalTo(iconImageView.snp.bottom).offset(12)
            make.horizontalEdges.equalToSuperview()
            make.height.equalTo(32)
            make.bottom.equalToSuperview()
        }

        tagStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalToSuperview()
        }

        addContentView(container)
    }

    private func setupBinding() {
        textField.rx.controlEvent(.editingDidEndOnExit)
            .bind(with: self) { owner, _ in
                owner.textField.resignFirstResponder()
            }
            .disposed(by: disposeBag)

        textField.rx.text
            .bind(to: selectedFolderRelay)
            .disposed(by: disposeBag)

        selectedFolderRelay
            .bind(with: self) { owner, folder in
                owner.textField.text = folder
            }
            .disposed(by: disposeBag)
    }

    private func loadExistingFolders() {
        let cards = RealmManager.shared.fetch(Card.self)

        var folderNames = Set<String>()
        folderNames.insert(NSLocalizedString("folder.default", comment: ""))

        for card in cards {
            if let folderName = card.customFolder, !folderName.isEmpty {
                folderNames.insert(folderName)
            }
        }

        updateTagButtons(with: Array(folderNames).sorted())
    }

    private func updateTagButtons(with folders: [String]) {
        tagStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        for folderName in folders {
            let button = createTagButton(title: folderName)
            tagStackView.addArrangedSubview(button)
        }
    }

    private func createTagButton(title: String) -> UIButton {
        let button = UIButton()
        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = ColorSystem.white.withAlphaComponent(0.3)
        config.baseForegroundColor = ColorSystem.darkGray
        config.cornerStyle = .capsule
        config.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12)

        var titleAttr = AttributeContainer()
        titleAttr.font = FontSystem.galmuriMono(size: 13)
        config.attributedTitle = AttributedString(title, attributes: titleAttr)

        button.configuration = config

        button.rx.tap
            .bind(with: self) { owner, _ in
                owner.selectedFolderRelay.accept(title)
            }
            .disposed(by: disposeBag)

        return button
    }

    func setFolder(_ folder: String?) {
        selectedFolderRelay.accept(folder)
    }

    func refreshFolderTags() {
        loadExistingFolders()
    }
}
