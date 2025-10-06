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

    private let dateCard: UIView = {
        let view = UIView()
        view.backgroundColor = ColorSystem.cardBackground
        view.layer.cornerRadius = 12
        return view
    }()

    private let dateLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("card_info.date", comment: "")
        label.font = FontSystem.galmuriMono(size: 14)
        label.textColor = ColorSystem.labelTitle
        return label
    }()

    private let dateIconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "calendar")
        imageView.tintColor = ColorSystem.labelPrimary
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    let dateValueLabel: UILabel = {
        let label = UILabel()
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateStyle = .long
        label.text = formatter.string(from: Date())
        label.font = FontSystem.galmuriMono(size: 16)
        label.textColor = ColorSystem.labelPrimary
        return label
    }()

    let dateSelectButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .clear
        return button
    }()

    private let memoCard: UIView = {
        let view = UIView()
        view.backgroundColor = ColorSystem.cardBackground
        view.layer.cornerRadius = 12
        return view
    }()

    private let memoLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("card_info.memo", comment: "")
        label.font = FontSystem.galmuriMono(size: 14)
        label.textColor = ColorSystem.labelTitle
        return label
    }()

    let memoTextView: UITextView = {
        let textView = UITextView()
        textView.font = FontSystem.galmuriMono(size: 16)
        textView.textColor = ColorSystem.labelSecondary
        textView.backgroundColor = .clear
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 8, bottom: 12, right: 8)
        return textView
    }()

    let characterCountLabel: UILabel = {
        let label = UILabel()
        label.text = "0"
        label.font = FontSystem.galmuriMono(size: 12)
        label.textColor = ColorSystem.labelPrimary
        label.textAlignment = .right
        return label
    }()

    private let locationCard: UIView = {
        let view = UIView()
        view.backgroundColor = ColorSystem.cardBackground
        view.layer.cornerRadius = 12
        return view
    }()

    private let locationLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("card_info.location", comment: "")
        label.font = FontSystem.galmuriMono(size: 14)
        label.textColor = ColorSystem.labelTitle
        return label
    }()

    let selectedLocationLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("card_info.location_placeholder", comment: "")
        label.font = FontSystem.galmuriMono(size: 14)
        label.textColor = ColorSystem.labelPrimary
        label.numberOfLines = 2
        return label
    }()

    let searchLocationButton: UIButton = {
        let button = UIButton()
        var config = UIButton.Configuration.filled()
        config.title = NSLocalizedString("card_info.search_location", comment: "")
        config.image = UIImage(systemName: "magnifyingglass")
        config.imagePlacement = .leading
        config.imagePadding = 8
        config.baseBackgroundColor = .clear
        config.baseForegroundColor = .black
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

    let mapView: MKMapView = {
        let mapView = MKMapView()
        mapView.layer.cornerRadius = 12
        mapView.clipsToBounds = true
        mapView.isHidden = true
        return mapView
    }()

    private let secretCard: UIView = {
        let view = UIView()
        view.backgroundColor = ColorSystem.cardBackground
        view.layer.cornerRadius = 12
        return view
    }()

    private let secretLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("card_info.secret", comment: "")
        label.font = FontSystem.galmuriMono(size: 14)
        label.textColor = ColorSystem.labelTitle
        return label
    }()

    private let secretDescriptionLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("card_info.secret_description", comment: "")
        label.font = FontSystem.galmuriMono(size: 12)
        label.textColor = ColorSystem.labelPrimary
        return label
    }()

    let secretSwitch: UISwitch = {
        let switchControl = UISwitch()
        return switchControl
    }()

    let deleteCard: UIView = {
        let view = UIView()
        view.backgroundColor = ColorSystem.cardBackground
        view.layer.cornerRadius = 12
        view.isHidden = true
        return view
    }()

    private let deleteLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("card_info.delete", comment: "")
        label.font = FontSystem.galmuriMono(size: 14)
        label.textColor = ColorSystem.labelTitle
        return label
    }()

    lazy var deleteButton: UIButton = {
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

    var mapViewHeightConstraint: Constraint?
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
        dateCard.addSubview(dateLabel)
        dateCard.addSubview(dateValueLabel)
        dateCard.addSubview(dateIconImageView)
        dateCard.addSubview(dateSelectButton)

        contentView.addSubview(memoCard)
        memoCard.addSubview(memoLabel)
        memoCard.addSubview(memoTextView)
        memoCard.addSubview(characterCountLabel)

        contentView.addSubview(locationCard)
        locationCard.addSubview(locationLabel)
        locationCard.addSubview(selectedLocationLabel)
        locationCard.addSubview(searchLocationButton)
        locationCard.addSubview(mapView)

        contentView.addSubview(secretCard)
        secretCard.addSubview(secretLabel)
        secretCard.addSubview(secretDescriptionLabel)
        secretCard.addSubview(secretSwitch)

        contentView.addSubview(deleteCard)
        deleteCard.addSubview(deleteLabel)
        deleteCard.addSubview(deleteButton)

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
            make.height.equalTo(80)
        }

        dateLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(16)
        }

        dateIconImageView.snp.makeConstraints { make in
            make.top.equalTo(dateLabel.snp.bottom).offset(8)
            make.leading.equalToSuperview().inset(16)
            make.width.height.equalTo(20)
            make.bottom.equalToSuperview().inset(16)
        }

        dateValueLabel.snp.makeConstraints { make in
            make.leading.equalTo(dateIconImageView.snp.trailing).offset(8)
            make.centerY.equalTo(dateIconImageView)
        }

        dateSelectButton.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        memoCard.snp.makeConstraints { make in
            make.top.equalTo(dateCard.snp.bottom).offset(16)
            make.horizontalEdges.equalToSuperview().inset(20)
        }

        memoLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(16)
        }

        memoTextView.snp.makeConstraints { make in
            make.top.equalTo(memoLabel.snp.bottom).offset(4)
            make.horizontalEdges.equalToSuperview().inset(8)
            make.height.equalTo(100)
        }

        characterCountLabel.snp.makeConstraints { make in
            make.top.equalTo(memoTextView.snp.bottom).offset(4)
            make.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().inset(12)
        }

        locationCard.snp.makeConstraints { make in
            make.top.equalTo(memoCard.snp.bottom).offset(16)
            make.horizontalEdges.equalToSuperview().inset(20)
        }

        locationLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(16)
        }

        selectedLocationLabel.snp.makeConstraints { make in
            make.top.equalTo(locationLabel.snp.bottom).offset(8)
            make.horizontalEdges.equalToSuperview().inset(16)
        }

        searchLocationButton.snp.makeConstraints { make in
            make.top.equalTo(selectedLocationLabel.snp.bottom).offset(12)
            make.horizontalEdges.equalToSuperview().inset(16)
            make.height.equalTo(44)
        }

        mapView.snp.makeConstraints { make in
            make.top.equalTo(searchLocationButton.snp.bottom).offset(12)
            make.horizontalEdges.equalToSuperview().inset(16)
            mapViewHeightConstraint = make.height.equalTo(0).constraint
            make.bottom.equalToSuperview().inset(16)
        }

        secretCard.snp.makeConstraints { make in
            make.top.equalTo(locationCard.snp.bottom).offset(16)
            make.horizontalEdges.equalToSuperview().inset(20)
        }

        secretLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(16)
        }

        secretDescriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(secretLabel.snp.bottom).offset(4)
            make.leading.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().inset(16)
        }

        secretSwitch.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().inset(16)
        }

        deleteCard.snp.makeConstraints { make in
            make.top.equalTo(secretCard.snp.bottom).offset(16)
            make.horizontalEdges.equalToSuperview().inset(20)
            make.bottom.equalToSuperview().offset(-100)
        }

        deleteLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(16)
        }

        deleteButton.snp.makeConstraints { make in
            make.top.equalTo(deleteLabel.snp.bottom).offset(12)
            make.horizontalEdges.equalToSuperview().inset(16)
            make.height.equalTo(44)
            make.bottom.equalToSuperview().inset(16)
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
        searchLocationButton.applyGradient(.searchLocationButton)
    }
}
