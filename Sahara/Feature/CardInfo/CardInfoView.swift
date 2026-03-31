//
//  CardInfoView.swift
//  Sahara
//
//  Created by 금가경 on 10/6/25.
//

import MapKit
import SnapKit
import UIKit

final class CardInfoView: UIView {
    let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        return scrollView
    }()

    private let contentView = UIView()

    private let photoContainer: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 16
        view.clipsToBounds = true
        return view
    }()

    let photoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = true
        return imageView
    }()

    lazy var photoSelectButton: UIButton = {
        let button = UIButton()
        let iconSize = CGSize(width: 20, height: 20)
        let resizedImage = UIImage(named: "editBox").flatMap { original in
            UIGraphicsImageRenderer(size: iconSize).image { _ in
                original.draw(in: CGRect(origin: .zero, size: iconSize))
            }.withRenderingMode(.alwaysTemplate)
        }
        button.setImage(resizedImage, for: .normal)
        button.tintColor = .token(.textPrimary)
        button.imageView?.contentMode = .scaleAspectFit
        button.applyGlassCardStyle(cornerRadius: 16)
        return button
    }()

    lazy var photoEditButton: UIButton = {
        let button = UIButton()
        var config = UIButton.Configuration.filled()
        let iconSize = CGSize(width: 20, height: 20)
        config.image = UIImage(named: "editBox").flatMap { original in
            UIGraphicsImageRenderer(size: iconSize).image { _ in
                original.draw(in: CGRect(origin: .zero, size: iconSize))
            }.withRenderingMode(.alwaysTemplate)
        }
        config.baseBackgroundColor = .token(.backgroundPrimary).withAlphaComponent(0.9)
        config.baseForegroundColor = .token(.textPrimary)
        config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)
        button.configuration = config
        button.layer.cornerRadius = 8
        button.clipsToBounds = true
        button.isHidden = true
        return button
    }()

    let dateCard = DateSelectionCard()
    let memoCard = MemoCard()
    let folderCard = FolderSelectionCard()
    let locationCard = LocationSelectionCard()
    let biometricLockCard = BiometricLockCard()
    let deleteCard = DeleteCard()

    var photoImageHeightConstraint: Constraint?

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private let cardStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 12
        return stackView
    }()

    private func configureUI() {
        addSubview(scrollView)
        scrollView.addSubview(contentView)

        contentView.addSubview(photoContainer)
        photoContainer.addSubview(photoImageView)
        photoContainer.addSubview(photoEditButton)
        contentView.addSubview(photoSelectButton)
        contentView.addSubview(cardStackView)

        [dateCard, memoCard, folderCard, locationCard, biometricLockCard, deleteCard].forEach {
            cardStackView.addArrangedSubview($0)
        }

        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        contentView.snp.makeConstraints { make in
            make.edges.equalTo(scrollView)
            make.width.equalTo(scrollView)
        }

        photoContainer.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.horizontalEdges.equalToSuperview().inset(20)
            photoImageHeightConstraint = make.height.equalTo(150).constraint
        }

        photoImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        photoEditButton.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(12)
            make.width.height.equalTo(36)
        }

        photoSelectButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.horizontalEdges.equalToSuperview().inset(20)
            make.height.equalTo(150)
        }

        cardStackView.snp.makeConstraints { make in
            make.top.equalTo(photoContainer.snp.bottom).offset(12)
            make.horizontalEdges.equalToSuperview().inset(20)
            make.bottom.equalToSuperview().offset(-40)
        }
    }

    func updatePhotoImageHeight(for image: UIImage) {
        let aspectRatio = image.size.height / image.size.width

        photoContainer.snp.remakeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.horizontalEdges.equalToSuperview().inset(20)
            make.height.equalTo(photoContainer.snp.width).multipliedBy(aspectRatio)
        }

        layoutIfNeeded()
    }

    func resetPhotoImageHeight() {
        photoContainer.snp.remakeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.horizontalEdges.equalToSuperview().inset(20)
            make.height.equalTo(150)
        }

        layoutIfNeeded()
    }

    func addPhotoContainerInteraction(_ interaction: UIInteraction) {
        photoContainer.addInteraction(interaction)
    }

    func setDropHighlight(_ highlighted: Bool) {
        photoContainer.layer.borderWidth = highlighted ? 2 : 0
        photoContainer.layer.borderColor = highlighted ? UIColor.token(.accent).cgColor : nil
    }

    func applyGradients() {
        locationCard.searchButton.applyGradient(.fresh)
    }
}
