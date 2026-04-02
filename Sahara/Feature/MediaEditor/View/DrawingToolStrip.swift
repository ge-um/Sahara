//
//  DrawingToolStrip.swift
//  Sahara
//
//  Created by 금가경 on 3/25/26.
//

import PencilKit
import SnapKit
import UIKit

final class DrawingToolStrip: UIView {

    // MARK: - Callbacks

    var onToolChanged: ((PKTool) -> Void)?
    var onCustomColorRequested: (() -> Void)?
    var onUndoTapped: (() -> Void)?
    var onRedoTapped: (() -> Void)?

    // MARK: - State

    private var selectedTool: DrawingTool = .pen
    private var selectedColor: UIColor = .black
    private var lineWidth: CGFloat = 5

    // MARK: - Constants

    private let colorPresets: [UIColor] = [
        .black, .white, .systemRed, .systemOrange,
        .systemYellow, .systemGreen, .systemBlue, .systemPurple
    ]

    // MARK: - UI (Top Row — Colors)

    private let topRowStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 6
        return stack
    }()

    // MARK: - UI (Bottom Row — Undo/Redo + Slider + Tools)

    private let bottomScrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsHorizontalScrollIndicator = false
        sv.showsVerticalScrollIndicator = false
        return sv
    }()

    private let bottomRowStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 10
        return stack
    }()

    private let toolStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 2
        return stack
    }()

    private let widthSlider: UISlider = {
        let slider = UISlider()
        slider.minimumValue = 1
        slider.maximumValue = 20
        slider.value = 5
        slider.minimumTrackTintColor = .black
        return slider
    }()

    private let undoButton: UIButton = {
        let button = UIButton()
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: "arrow.uturn.backward")?
            .withConfiguration(UIImage.SymbolConfiguration(pointSize: 14, weight: .medium))
        config.baseForegroundColor = .black
        config.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 6, bottom: 6, trailing: 6)
        button.configuration = config
        button.isEnabled = false
        button.alpha = 0.3
        return button
    }()

    private let redoButton: UIButton = {
        let button = UIButton()
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: "arrow.uturn.forward")?
            .withConfiguration(UIImage.SymbolConfiguration(pointSize: 14, weight: .medium))
        config.baseForegroundColor = .black
        config.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 6, bottom: 6, trailing: 6)
        button.configuration = config
        button.isEnabled = false
        button.alpha = 0.3
        return button
    }()

    private var toolButtons: [UIButton] = []
    private var colorButtons: [UIButton] = []

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        selectTool(.pen)
        selectColorButton(at: 0)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Public

    func updateColor(_ color: UIColor) {
        selectedColor = color
        deselectAllColorButtons()
        notifyToolChanged()
    }

    func updateUndoRedoState(canUndo: Bool, canRedo: Bool) {
        undoButton.isEnabled = canUndo
        undoButton.alpha = canUndo ? 1.0 : 0.3
        redoButton.isEnabled = canRedo
        redoButton.alpha = canRedo ? 1.0 : 0.3
    }

    // MARK: - Setup

    override func layoutSubviews() {
        super.layoutSubviews()
        applyGradient(.tabBar)

        let contentWidth = bottomScrollView.contentSize.width
        let scrollWidth = bottomScrollView.bounds.width
        let newInset: UIEdgeInsets
        if contentWidth > 0, contentWidth < scrollWidth {
            let horizontal = (scrollWidth - contentWidth) / 2
            newInset = UIEdgeInsets(top: 0, left: horizontal, bottom: 0, right: horizontal)
        } else {
            newInset = .zero
        }
        if bottomScrollView.contentInset != newInset {
            bottomScrollView.contentInset = newInset
        }
    }

    private func setupUI() {
        layer.cornerRadius = DesignToken.CornerRadius.card
        clipsToBounds = true

        let rootStack = UIStackView()
        rootStack.axis = .vertical
        rootStack.spacing = 6
        rootStack.alignment = .center

        addSubview(rootStack)
        rootStack.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview().inset(12)
            make.centerY.equalToSuperview()
        }

        setupTopRow()
        setupBottomRow()

        rootStack.addArrangedSubview(topRowStack)
        rootStack.addArrangedSubview(bottomScrollView)

        bottomScrollView.snp.makeConstraints { make in
            make.width.equalTo(rootStack)
        }
    }

    // MARK: - Top Row (Colors)

    private func setupTopRow() {
        for (index, color) in colorPresets.enumerated() {
            let button = makeColorButton(color: color)
            button.tag = index
            button.addTarget(self, action: #selector(colorButtonTapped(_:)), for: .touchUpInside)
            colorButtons.append(button)
            topRowStack.addArrangedSubview(button)
        }

        let customButton = UIButton()
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: "plus.circle.fill")?
            .withConfiguration(UIImage.SymbolConfiguration(pointSize: 18))
        config.baseForegroundColor = DesignToken.Overlay.heavyOverlay
        config.contentInsets = NSDirectionalEdgeInsets(top: 2, leading: 2, bottom: 2, trailing: 2)
        customButton.configuration = config

        customButton.snp.makeConstraints { make in
            make.width.height.equalTo(26)
        }

        customButton.addTarget(self, action: #selector(customColorTapped), for: .touchUpInside)
        topRowStack.addArrangedSubview(customButton)

    }

    // MARK: - Bottom Row (Undo/Redo + Slider + Tools)

    private func setupBottomRow() {
        bottomScrollView.addSubview(bottomRowStack)

        bottomRowStack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalToSuperview()
        }

        setupUndoRedoButtons()
        setupSeparator()
        setupWidthSlider()
        setupSeparator()
        setupToolButtons()
    }

    private func setupUndoRedoButtons() {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 2

        undoButton.snp.makeConstraints { make in
            make.width.height.equalTo(32)
        }
        redoButton.snp.makeConstraints { make in
            make.width.height.equalTo(32)
        }

        undoButton.addTarget(self, action: #selector(undoTapped), for: .touchUpInside)
        redoButton.addTarget(self, action: #selector(redoTapped), for: .touchUpInside)

        stack.addArrangedSubview(undoButton)
        stack.addArrangedSubview(redoButton)
        bottomRowStack.addArrangedSubview(stack)
    }

    private func setupWidthSlider() {
        widthSlider.addTarget(self, action: #selector(sliderChanged(_:)), for: .valueChanged)

        widthSlider.snp.makeConstraints { make in
            make.width.equalTo(100)
        }

        bottomRowStack.addArrangedSubview(widthSlider)
    }

    private func setupToolButtons() {
        for tool in DrawingTool.allCases {
            let button = UIButton()
            var config = UIButton.Configuration.plain()
            config.image = UIImage(systemName: tool.iconName)?
                .withConfiguration(UIImage.SymbolConfiguration(pointSize: 16, weight: .medium))
            config.baseForegroundColor = .black
            config.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 6, bottom: 6, trailing: 6)
            button.configuration = config
            button.alpha = 0.5

            button.snp.makeConstraints { make in
                make.width.height.equalTo(36)
            }

            button.addTarget(self, action: #selector(toolButtonTapped(_:)), for: .touchUpInside)
            toolButtons.append(button)
            toolStack.addArrangedSubview(button)
        }

        bottomRowStack.addArrangedSubview(toolStack)
    }

    private func setupSeparator() {
        let separator = UIView()
        separator.backgroundColor = DesignToken.Overlay.subtleBorder

        separator.snp.makeConstraints { make in
            make.width.equalTo(1)
            make.height.equalTo(24)
        }

        bottomRowStack.addArrangedSubview(separator)
    }

    private func makeColorButton(color: UIColor) -> UIButton {
        let button = UIButton()
        button.backgroundColor = color
        button.layer.cornerRadius = 11
        button.layer.borderWidth = 2
        button.layer.borderColor = UIColor.clear.cgColor
        button.clipsToBounds = true

        if color == .white {
            button.layer.borderColor = DesignToken.Overlay.subtleBorder.cgColor
        }

        button.snp.makeConstraints { make in
            make.width.height.equalTo(22)
        }

        return button
    }

    // MARK: - Actions

    @objc private func undoTapped() {
        onUndoTapped?()
    }

    @objc private func redoTapped() {
        onRedoTapped?()
    }

    @objc private func toolButtonTapped(_ sender: UIButton) {
        guard let index = toolButtons.firstIndex(of: sender) else { return }
        let tool = DrawingTool.allCases[index]
        selectTool(tool)
        notifyToolChanged()
    }

    @objc private func colorButtonTapped(_ sender: UIButton) {
        selectColorButton(at: sender.tag)
        selectedColor = colorPresets[sender.tag]
        notifyToolChanged()
    }

    @objc private func customColorTapped() {
        onCustomColorRequested?()
    }

    @objc private func sliderChanged(_ sender: UISlider) {
        lineWidth = CGFloat(sender.value)
        notifyToolChanged()
    }

    // MARK: - Selection

    private func selectTool(_ tool: DrawingTool) {
        selectedTool = tool

        for (index, button) in toolButtons.enumerated() {
            let isSelected = DrawingTool.allCases[index] == tool
            button.alpha = isSelected ? 1.0 : 0.5
        }
    }

    private func selectColorButton(at index: Int) {
        deselectAllColorButtons()

        guard index < colorButtons.count else { return }
        let button = colorButtons[index]
        button.layer.borderColor = UIColor.black.cgColor
    }

    private func deselectAllColorButtons() {
        for (index, button) in colorButtons.enumerated() {
            if colorPresets[index] == .white {
                button.layer.borderColor = DesignToken.Overlay.subtleBorder.cgColor
            } else {
                button.layer.borderColor = UIColor.clear.cgColor
            }
        }
    }

    // MARK: - Notify

    private func notifyToolChanged() {
        let tool = selectedTool.pkTool(color: selectedColor, width: lineWidth)
        onToolChanged?(tool)
    }
}
