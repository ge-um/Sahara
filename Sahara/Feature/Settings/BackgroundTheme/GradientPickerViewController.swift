//
//  GradientPickerViewController.swift
//  Sahara
//

import SnapKit
import UIKit

final class GradientPickerViewController: UIViewController {
    private let onComplete: (String, String) -> Void
    private let gradientLayer = CAGradientLayer()

    private let previewView: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 16
        v.clipsToBounds = true
        return v
    }()

    private let startLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("background.gradient_start", comment: "")
        label.font = DesignToken.Typography.body.font
        label.textColor = .token(.textPrimary)
        return label
    }()

    private let endLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("background.gradient_end", comment: "")
        label.font = DesignToken.Typography.body.font
        label.textColor = .token(.textPrimary)
        return label
    }()

    private let startColorWell: UIColorWell = {
        let well = UIColorWell()
        well.selectedColor = UIColor(hex: "#FFBDFF")
        well.supportsAlpha = false
        return well
    }()

    private let endColorWell: UIColorWell = {
        let well = UIColorWell()
        well.selectedColor = UIColor(hex: "#6CA9FF")
        well.supportsAlpha = false
        return well
    }()

    private let doneButton: UIButton = {
        let button = UIButton()
        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = .clear
        config.baseForegroundColor = .token(.textPrimary)
        config.cornerStyle = .capsule
        config.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 24, bottom: 12, trailing: 24)

        var titleAttr = AttributeContainer()
        titleAttr.font = UIFont.typography(.body)
        config.attributedTitle = AttributedString(
            NSLocalizedString("common.save", comment: ""),
            attributes: titleAttr
        )

        button.configuration = config
        button.clipsToBounds = true
        return button
    }()

    init(onComplete: @escaping (String, String) -> Void) {
        self.onComplete = onComplete
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.token(.backgroundPrimary)
        configureUI()
        setupGradientLayer()

        startColorWell.addTarget(self, action: #selector(colorChanged), for: .valueChanged)
        endColorWell.addTarget(self, action: #selector(colorChanged), for: .valueChanged)
        doneButton.addTarget(self, action: #selector(doneTapped), for: .touchUpInside)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer.frame = previewView.bounds
        doneButton.applyGradient(.fresh, removeExisting: true)
    }

    private func configureUI() {
        view.addSubview(previewView)
        view.addSubview(startLabel)
        view.addSubview(startColorWell)
        view.addSubview(endLabel)
        view.addSubview(endColorWell)
        view.addSubview(doneButton)

        previewView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(24)
            make.horizontalEdges.equalToSuperview().inset(20)
            make.height.equalTo(120)
        }

        startLabel.snp.makeConstraints { make in
            make.top.equalTo(previewView.snp.bottom).offset(24)
            make.leading.equalToSuperview().inset(20)
        }

        startColorWell.snp.makeConstraints { make in
            make.centerY.equalTo(startLabel)
            make.trailing.equalToSuperview().inset(20)
            make.size.equalTo(44)
        }

        endLabel.snp.makeConstraints { make in
            make.top.equalTo(startLabel.snp.bottom).offset(20)
            make.leading.equalToSuperview().inset(20)
        }

        endColorWell.snp.makeConstraints { make in
            make.centerY.equalTo(endLabel)
            make.trailing.equalToSuperview().inset(20)
            make.size.equalTo(44)
        }

        doneButton.snp.makeConstraints { make in
            make.top.equalTo(endLabel.snp.bottom).offset(32)
            make.horizontalEdges.equalToSuperview().inset(40)
            make.height.equalTo(50)
        }
    }

    private func setupGradientLayer() {
        gradientLayer.locations = [0.0, 1.0]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        previewView.layer.insertSublayer(gradientLayer, at: 0)
        updatePreviewColors()
    }

    private func updatePreviewColors() {
        gradientLayer.colors = [
            startColorWell.selectedColor!.cgColor,
            endColorWell.selectedColor!.cgColor
        ]
    }

    @objc private func colorChanged() {
        updatePreviewColors()
    }

    @objc private func doneTapped() {
        let startHex = startColorWell.selectedColor?.toHex() ?? "#FFBDFF"
        let endHex = endColorWell.selectedColor?.toHex() ?? "#6CA9FF"
        dismiss(animated: true) { [weak self] in
            self?.onComplete(startHex, endHex)
        }
    }
}
