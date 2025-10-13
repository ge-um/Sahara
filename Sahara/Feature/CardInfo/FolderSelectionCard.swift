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

final class FolderSelectionCard: UIView {
    private let cardView: UIView = {
        let view = UIView()
        view.backgroundColor = ColorSystem.cardBackground
        view.layer.cornerRadius = 12
        return view
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("card_info.folder", comment: "")
        label.font = FontSystem.galmuriMono(size: 14)
        label.textColor = ColorSystem.labelTitle
        return label
    }()

    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "folder")
        imageView.tintColor = ColorSystem.labelPrimary
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    let textField: UITextField = {
        let textField = UITextField()
        textField.placeholder = NSLocalizedString("folder.default", comment: "")
        textField.font = FontSystem.galmuriMono(size: 16)
        textField.textColor = ColorSystem.labelPrimary
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

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureUI()
        setupBinding()
        loadExistingFolders()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureUI() {
        addSubview(cardView)
        cardView.addSubview(titleLabel)
        cardView.addSubview(iconImageView)
        cardView.addSubview(textField)
        cardView.addSubview(tagScrollView)
        tagScrollView.addSubview(tagStackView)

        cardView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        titleLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(16)
        }

        iconImageView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.leading.equalToSuperview().inset(16)
            make.width.height.equalTo(20)
        }

        textField.snp.makeConstraints { make in
            make.leading.equalTo(iconImageView.snp.trailing).offset(8)
            make.centerY.equalTo(iconImageView)
            make.trailing.equalToSuperview().inset(16)
        }

        tagScrollView.snp.makeConstraints { make in
            make.top.equalTo(iconImageView.snp.bottom).offset(12)
            make.horizontalEdges.equalToSuperview().inset(16)
            make.height.equalTo(32)
            make.bottom.equalToSuperview().inset(16)
        }

        tagStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalToSuperview()
        }
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
        let realm = try! Realm()
        let cards = realm.objects(Card.self)

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
        config.baseForegroundColor = ColorSystem.labelPrimary
        config.cornerStyle = .capsule
        config.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12)

        var titleAttr = AttributeContainer()
        titleAttr.font = FontSystem.galmuriMono(size: 12)
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
