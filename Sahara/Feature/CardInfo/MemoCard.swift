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

final class MemoCard: UIView {
    private let cardView: UIView = {
        let view = UIView()
        view.backgroundColor = ColorSystem.purpleGray20
        view.layer.cornerRadius = 12
        return view
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("card_info.memo", comment: "")
        label.font = FontSystem.galmuriMono(size: 14)
        label.textColor = ColorSystem.black
        return label
    }()

    let textView: UITextView = {
        let textView = UITextView()
        textView.font = FontSystem.galmuriMono(size: 16)
        textView.textColor = ColorSystem.charcoal
        textView.backgroundColor = .clear
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 8, bottom: 12, right: 8)
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

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureUI()
        setupRxBindings()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureUI() {
        addSubview(cardView)
        cardView.addSubview(titleLabel)
        cardView.addSubview(textView)
        cardView.addSubview(characterCountLabel)

        cardView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        titleLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(16)
        }

        textView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.horizontalEdges.equalToSuperview().inset(8)
            make.height.equalTo(100)
        }

        characterCountLabel.snp.makeConstraints { make in
            make.top.equalTo(textView.snp.bottom).offset(4)
            make.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().inset(12)
        }
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
                .font: FontSystem.galmuriMono(size: 16)
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
