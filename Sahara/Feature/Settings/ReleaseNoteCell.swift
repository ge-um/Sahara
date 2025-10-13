//
//  ReleaseNoteCell.swift
//  Sahara
//
//  Created by 금가경 on 10/12/25.
//

import SnapKit
import UIKit

final class ReleaseNoteCell: UITableViewCell, IsIdentifiable {
    private let versionLabel: UILabel = {
        let label = UILabel()
        label.font = FontSystem.galmuriBold(size: 14)
        label.textColor = ColorSystem.black
        return label
    }()

    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = FontSystem.galmuriMono(size: 12)
        label.textColor = ColorSystem.charcoal
        return label
    }()

    private let changesLabel: UILabel = {
        let label = UILabel()
        label.font = FontSystem.galmuriMono(size: 12)
        label.textColor = ColorSystem.darkGray
        label.numberOfLines = 0
        return label
    }()

    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = ColorSystem.lavender20
        view.layer.cornerRadius = 12
        return view
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureUI() {
        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(containerView)
        containerView.addSubview(versionLabel)
        containerView.addSubview(dateLabel)
        containerView.addSubview(changesLabel)

        containerView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.horizontalEdges.equalToSuperview()
            make.bottom.equalToSuperview().offset(-8)
        }

        versionLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.leading.equalToSuperview().offset(20)
        }

        dateLabel.snp.makeConstraints { make in
            make.centerY.equalTo(versionLabel)
            make.trailing.equalToSuperview().inset(20)
        }

        changesLabel.snp.makeConstraints { make in
            make.top.equalTo(versionLabel.snp.bottom).offset(12)
            make.horizontalEdges.equalToSuperview().inset(20)
            make.bottom.equalToSuperview().offset(-16)
        }
    }

    func configure(with releaseNote: ReleaseNote) {
        versionLabel.text = releaseNote.version
        dateLabel.text = releaseNote.dateString

        if releaseNote.changes.isEmpty {
            changesLabel.attributedText = nil
        } else {
            let bulletPoints = releaseNote.changes.map { "- \($0)" }.joined(separator: "\n")
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineHeightMultiple = 1.4

            let attributedString = NSAttributedString(
                string: bulletPoints,
                attributes: [
                    .font: FontSystem.galmuriMono(size: 14),
                    .foregroundColor: ColorSystem.darkGray,
                    .paragraphStyle: paragraphStyle
                ]
            )
            changesLabel.attributedText = attributedString
        }
    }
}
