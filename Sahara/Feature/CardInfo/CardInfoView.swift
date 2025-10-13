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

    let photoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.layer.cornerRadius = 16
        imageView.clipsToBounds = true
        imageView.isUserInteractionEnabled = true
        return imageView
    }()

    lazy var photoSelectButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "editBox"), for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.layer.cornerRadius = 16
        button.clipsToBounds = true
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

    private func configureUI() {
        addSubview(scrollView)
        scrollView.addSubview(contentView)

        contentView.addSubview(photoImageView)
        contentView.addSubview(photoSelectButton)
        contentView.addSubview(dateCard)
        contentView.addSubview(memoCard)
        contentView.addSubview(folderCard)
        contentView.addSubview(locationCard)
        contentView.addSubview(biometricLockCard)
        contentView.addSubview(deleteCard)

        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        contentView.snp.makeConstraints { make in
            make.edges.equalTo(scrollView)
            make.width.equalTo(scrollView)
        }

        photoImageView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.horizontalEdges.equalToSuperview().inset(20)
            photoImageHeightConstraint = make.height.equalTo(300).constraint
        }

        photoSelectButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.horizontalEdges.equalToSuperview().inset(20)
            make.height.equalTo(300)
        }

        dateCard.snp.makeConstraints { make in
            make.top.equalTo(photoImageView.snp.bottom).offset(20)
            make.horizontalEdges.equalToSuperview().inset(20)
        }

        memoCard.snp.makeConstraints { make in
            make.top.equalTo(dateCard.snp.bottom).offset(16)
            make.horizontalEdges.equalToSuperview().inset(20)
        }

        folderCard.snp.makeConstraints { make in
            make.top.equalTo(memoCard.snp.bottom).offset(16)
            make.horizontalEdges.equalToSuperview().inset(20)
        }

        locationCard.snp.makeConstraints { make in
            make.top.equalTo(folderCard.snp.bottom).offset(16)
            make.horizontalEdges.equalToSuperview().inset(20)
        }

        biometricLockCard.snp.makeConstraints { make in
            make.top.equalTo(locationCard.snp.bottom).offset(16)
            make.horizontalEdges.equalToSuperview().inset(20)
        }

        deleteCard.snp.makeConstraints { make in
            make.top.equalTo(biometricLockCard.snp.bottom).offset(16)
            make.horizontalEdges.equalToSuperview().inset(20)
            make.bottom.equalToSuperview().offset(-100)
        }
    }

    func updatePhotoImageHeight(for image: UIImage) {
        let aspectRatio = image.size.height / image.size.width

        photoImageView.snp.remakeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.horizontalEdges.equalToSuperview().inset(20)
            make.height.equalTo(photoImageView.snp.width).multipliedBy(aspectRatio)
        }

        layoutIfNeeded()
    }

    func resetPhotoImageHeight() {
        photoImageView.snp.remakeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.horizontalEdges.equalToSuperview().inset(20)
            make.height.equalTo(300)
        }

        layoutIfNeeded()
    }

    func applyGradients() {
        photoSelectButton.applyGradient(.barBack)
        locationCard.searchButton.applyGradient(.searchLocationButton)
    }
}
