//
//  MemoCard.swift
//  Sahara
//
//  Created by 금가경 on 10/12/25.
//

import RxCocoa
import RxSwift
import SnapKit
import UIKit

final class MemoCard: BaseCard {
    let textView: UITextView = {
        let textView = UITextView()
        textView.font = FontSystem.galmuriMono(size: 14)
        textView.textColor = ColorSystem.charcoal
        textView.backgroundColor = .clear
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        return textView
    }()

    let characterCountLabel: UILabel = {
        let label = UILabel()
        label.text = "0"
        label.font = FontSystem.galmuriMono(size: 12)
        label.textColor = ColorSystem.darkGray
        label.textAlignment = .right
        return label
    }()

    private let disposeBag = DisposeBag()
    private let placeholderText = NSLocalizedString("card_info.memo_placeholder", comment: "")

    init() {
        super.init(title: NSLocalizedString("card_info.memo", comment: ""))
        configureContent()
        setupRxBindings()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureContent() {
        let container = UIView()
        container.addSubview(textView)
        container.addSubview(characterCountLabel)

        textView.snp.makeConstraints { make in
            make.top.horizontalEdges.equalToSuperview()
            make.height.equalTo(100)
        }

        characterCountLabel.snp.makeConstraints { make in
            make.top.equalTo(textView.snp.bottom).offset(4)
            make.trailing.equalToSuperview()
            make.bottom.equalToSuperview().inset(4)
        }

        addContentView(container)
    }

    private func setupRxBindings() {
        textView.rx.didBeginEditing
            .withUnretained(self)
            .bind { owner, _ in
                if owner.textView.textColor == ColorSystem.darkGray {
                    owner.textView.text = ""
                    owner.textView.textColor = ColorSystem.charcoal
                }
            }
            .disposed(by: disposeBag)

        textView.rx.didEndEditing
            .withUnretained(self)
            .bind { owner, _ in
                if owner.textView.text.isEmpty {
                    owner.showPlaceholder()
                }
            }
            .disposed(by: disposeBag)

        textView.rx.text
            .orEmpty
            .withUnretained(self)
            .bind { owner, text in
                let count = owner.textView.textColor == ColorSystem.darkGray ? 0 : text.count
                owner.characterCountLabel.text = "\(count)"
                owner.characterCountLabel.textColor = ColorSystem.darkGray
            }
            .disposed(by: disposeBag)
    }

    func showPlaceholder() {
        textView.attributedText = NSAttributedString(
            string: placeholderText,
            attributes: [
                .foregroundColor: ColorSystem.darkGray,
                .font: FontSystem.galmuriMono(size: 14)
            ]
        )
        characterCountLabel.text = "0"
        characterCountLabel.textColor = ColorSystem.darkGray
    }

    func setMemo(_ memo: String) {
        textView.text = memo
        textView.textColor = ColorSystem.charcoal
        characterCountLabel.text = "\(memo.count)"
    }
}
