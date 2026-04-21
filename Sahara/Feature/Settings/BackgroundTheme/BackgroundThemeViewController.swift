//
//  BackgroundThemeViewController.swift
//  Sahara
//

import PhotosUI
import RxCocoa
import RxSwift
import SnapKit
import UIKit

final class BackgroundThemeViewController: UIViewController {
    private let viewModel: BackgroundThemeViewModel
    private let disposeBag = DisposeBag()

    private let solidColorRelay = PublishRelay<String>()
    private let gradientRelay = PublishRelay<String>()
    private let customGradientRelay = PublishRelay<(String, String)>()
    private let photoRelay = PublishRelay<Data>()
    private let dotPatternRelay = BehaviorRelay<Bool>(value: true)
    private let applyRelay = PublishRelay<Void>()


    private let customNavigationBar = CustomNavigationBar()

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
        return sv
    }()

    private let contentView = UIView()

    private let previewContainer: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 20
        v.clipsToBounds = true
        return v
    }()

    private let previewLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("background.preview", comment: "")
        label.font = DesignToken.Typography.caption.font
        label.textColor = .token(.textSecondary)
        label.textAlignment = .center
        return label
    }()

    private let segmentedControl: UISegmentedControl = {
        let sc = UISegmentedControl(items: [
            NSLocalizedString("background.solid_color", comment: ""),
            NSLocalizedString("background.gradient", comment: ""),
            NSLocalizedString("background.photo", comment: "")
        ])
        sc.selectedSegmentIndex = 0
        sc.setTitleTextAttributes([.font: DesignToken.Typography.caption.font], for: .normal)
        sc.setTitleTextAttributes([.font: DesignToken.Typography.caption.font], for: .selected)
        return sc
    }()

    private let colorGridView = UIView()
    private let gradientGridView = UIView()
    private let photoSelectionView = UIView()
    private let dotPatternContainerView: UIView = {
        let v = UIView()
        v.applyGlassCardStyle()
        return v
    }()
    private var dotPatternTopConstraints: [Constraint] = []

    private let dotPatternSwitch: UISwitch = {
        let s = UISwitch()
        s.onTintColor = .token(.accent)
        return s
    }()

    private let dotPatternLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("background.dot_pattern", comment: "")
        label.font = DesignToken.Typography.caption.font
        label.textColor = .token(.textPrimary)
        return label
    }()

    private let saveButton: UIButton = .makeSaveButton()

    private var colorCells: [UIView] = []
    private var gradientCells: [UIView] = []
    private var presetColors: [String] = []
    private var lastColorGridWidth: CGFloat = 0
    private var colorGridDisposeBag = DisposeBag()
    private var colorGridHeightConstraint: Constraint?
    private var currentBackgroundConfig: BackgroundConfig?

    init(viewModel: BackgroundThemeViewModel = BackgroundThemeViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        setupCustomNavigationBar()
        configureUI()
        bind()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        saveButton.applyGradient(.ctaPink, removeExisting: true)
        rebuildColorGridIfNeeded()
    }

    private func setupCustomNavigationBar() {
        customNavigationBar.configure(title: NSLocalizedString("background.title", comment: ""))
        customNavigationBar.onLeftButtonTapped = { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }
    }

    private func configureUI() {
        view.applyBackgroundConfig(BackgroundThemeService.shared.currentConfig.value)

        view.addSubview(customNavigationBar)
        view.addSubview(saveButton)
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        customNavigationBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.horizontalEdges.equalToSuperview()
            make.height.equalTo(54)
        }

        saveButton.snp.makeConstraints { make in
            make.trailing.equalTo(customNavigationBar).inset(16)
            make.centerY.equalTo(customNavigationBar)
            make.width.greaterThanOrEqualTo(40)
            make.height.equalTo(36)
        }

        scrollView.snp.makeConstraints { make in
            make.top.equalTo(customNavigationBar.snp.bottom)
            make.horizontalEdges.bottom.equalToSuperview()
        }

        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(scrollView)
        }

        setupPreview()
        setupSegmentedControl()
        setupSelectionViews()
        setupDotPatternToggle()
        setupContentBottom()
    }

    private func setupPreview() {
        contentView.addSubview(previewContainer)
        previewContainer.addSubview(previewLabel)

        previewContainer.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.horizontalEdges.equalToSuperview().inset(20)
            make.height.equalTo(180)
        }

        previewLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }

    private func setupSegmentedControl() {
        contentView.addSubview(segmentedControl)
        segmentedControl.snp.makeConstraints { make in
            make.top.equalTo(previewContainer.snp.bottom).offset(20)
            make.horizontalEdges.equalToSuperview().inset(20)
            make.height.equalTo(36)
        }
    }

    private func setupSelectionViews() {
        contentView.addSubview(colorGridView)
        contentView.addSubview(gradientGridView)
        contentView.addSubview(photoSelectionView)

        let selectionTop = segmentedControl.snp.bottom

        colorGridView.snp.makeConstraints { make in
            make.top.equalTo(selectionTop).offset(20)
            make.horizontalEdges.equalToSuperview().inset(20)
        }

        gradientGridView.snp.makeConstraints { make in
            make.top.equalTo(selectionTop).offset(20)
            make.horizontalEdges.equalToSuperview().inset(20)
        }

        photoSelectionView.snp.makeConstraints { make in
            make.top.equalTo(selectionTop).offset(20)
            make.horizontalEdges.equalToSuperview().inset(20)
        }

        gradientGridView.isHidden = true
        photoSelectionView.isHidden = true

        setupPhotoButton()
    }

    private func setupPhotoButton() {
        let addButton = UIButton(type: .system)
        addButton.setImage(UIImage(named: "image"), for: .normal)
        addButton.tintColor = .token(.textSecondary)
        addButton.setTitle("  " + NSLocalizedString("background.select_photo", comment: ""), for: .normal)
        addButton.titleLabel?.font = DesignToken.Typography.caption.font
        addButton.setTitleColor(.token(.textSecondary), for: .normal)
        addButton.applyGlassCardStyle()
        addButton.rx.tap
            .subscribe(onNext: { [weak self] in self?.presentPhotoPicker() })
            .disposed(by: disposeBag)

        photoSelectionView.addSubview(addButton)
        addButton.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalTo(160)
        }
    }

    private func setupDotPatternToggle() {
        contentView.addSubview(dotPatternContainerView)

        dotPatternContainerView.addSubview(dotPatternLabel)
        dotPatternContainerView.addSubview(dotPatternSwitch)

        dotPatternContainerView.snp.makeConstraints { make in
            let c0 = make.top.equalTo(colorGridView.snp.bottom).offset(20).constraint
            let c1 = make.top.equalTo(gradientGridView.snp.bottom).offset(20).constraint
            let c2 = make.top.equalTo(photoSelectionView.snp.bottom).offset(20).constraint
            dotPatternTopConstraints = [c0, c1, c2]
            c1.deactivate()
            c2.deactivate()
            make.horizontalEdges.equalToSuperview().inset(20)
            make.height.equalTo(44)
        }

        dotPatternLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(20)
            make.centerY.equalToSuperview()
        }

        dotPatternSwitch.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(20)
            make.centerY.equalToSuperview()
        }
    }

    private func setupContentBottom() {
        dotPatternContainerView.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-40)
        }
    }

    private func bind() {
        let input = BackgroundThemeViewModel.Input(
            solidColorSelected: solidColorRelay.asObservable(),
            gradientSelected: gradientRelay.asObservable(),
            customGradientSelected: customGradientRelay.asObservable(),
            photoSelected: photoRelay.asObservable(),
            dotPatternToggled: dotPatternRelay.asObservable(),
            applyTapped: applyRelay.asObservable()
        )

        let output = viewModel.transform(input: input)

        dotPatternSwitch.rx.isOn
            .bind(to: dotPatternRelay)
            .disposed(by: disposeBag)

        saveButton.rx.tap
            .bind(to: applyRelay)
            .disposed(by: disposeBag)

        segmentedControl.rx.selectedSegmentIndex
            .subscribe(onNext: { [weak self] index in
                self?.switchSelectionTab(to: index)
            })
            .disposed(by: disposeBag)

        output.presetColors
            .drive(onNext: { [weak self] colors in
                self?.buildColorGrid(colors: colors)
            })
            .disposed(by: disposeBag)

        output.availableGradients
            .drive(onNext: { [weak self] gradients in
                self?.buildGradientGrid(gradients: gradients)
            })
            .disposed(by: disposeBag)

        output.currentConfig
            .drive(onNext: { [weak self] config in
                self?.currentBackgroundConfig = config
                self?.updatePreview(config: config)
                self?.updateSelection(config: config)
                self?.dotPatternSwitch.isOn = config.isDotPatternEnabled
            })
            .disposed(by: disposeBag)

        output.applied
            .drive(onNext: { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            })
            .disposed(by: disposeBag)
    }

    private func buildColorGrid(colors: [String]) {
        presetColors = colors
        lastColorGridWidth = 0
        rebuildColorGridIfNeeded()
    }

    private func rebuildColorGridIfNeeded() {
        let width = scrollView.bounds.width - 40
        guard width > 0, !presetColors.isEmpty, width != lastColorGridWidth else { return }
        lastColorGridWidth = width
        rebuildColorGrid(width: width)
    }

    private func rebuildColorGrid(width: CGFloat) {
        colorGridView.subviews.forEach { $0.removeFromSuperview() }
        colorCells.removeAll()
        colorGridDisposeBag = DisposeBag()

        let spacing: CGFloat = 12
        let cellSize: CGFloat = 48
        let columns = max(1, Int((width + spacing) / (cellSize + spacing)))
        let allItems = presetColors.count + 1

        for index in 0..<allItems {
            let isPickerButton = index == presetColors.count
            let cell = UIView()
            cell.layer.cornerRadius = cellSize / 2
            cell.clipsToBounds = true

            if isPickerButton {
                cell.backgroundColor = .token(.backgroundCard)
                cell.layer.borderWidth = 1
                cell.layer.borderColor = UIColor.token(.textSecondary).cgColor
                let icon = UIImageView(image: UIImage(systemName: "plus"))
                icon.tintColor = .token(.textSecondary)
                icon.contentMode = .scaleAspectFit
                cell.addSubview(icon)
                icon.snp.makeConstraints { $0.center.equalToSuperview(); $0.size.equalTo(20) }

                let tap = UITapGestureRecognizer()
                tap.rx.event
                    .subscribe(onNext: { [weak self] _ in self?.presentSolidColorPicker() })
                    .disposed(by: colorGridDisposeBag)
                cell.addGestureRecognizer(tap)
            } else {
                let hex = presetColors[index]
                cell.backgroundColor = UIColor(hex: hex)
                cell.tag = index
                cell.accessibilityIdentifier = "sahara.bgTheme.solid.\(index)"

                if hex == "#FFFFFF" || hex == "#F9FFFF" || hex == "#FFFFC5" {
                    cell.layer.borderWidth = 1
                    cell.layer.borderColor = UIColor.token(.textSecondary).cgColor
                }

                let tap = UITapGestureRecognizer()
                tap.rx.event
                    .map { _ in hex }
                    .bind(to: solidColorRelay)
                    .disposed(by: colorGridDisposeBag)
                cell.addGestureRecognizer(tap)
                colorCells.append(cell)
            }

            colorGridView.addSubview(cell)

            let row = index / columns
            let col = index % columns

            cell.snp.makeConstraints { make in
                make.width.height.equalTo(cellSize)
                make.leading.equalToSuperview().offset(CGFloat(col) * (cellSize + spacing))
                make.top.equalToSuperview().offset(CGFloat(row) * (cellSize + spacing))
            }
        }

        let totalRows = (allItems + columns - 1) / columns
        let gridHeight = CGFloat(totalRows) * cellSize + CGFloat(max(0, totalRows - 1)) * spacing
        colorGridHeightConstraint?.deactivate()
        colorGridView.snp.makeConstraints { make in
            colorGridHeightConstraint = make.height.equalTo(gridHeight).constraint
        }

        if let config = currentBackgroundConfig {
            updateSelection(config: config)
        }
    }

    private func buildGradientGrid(gradients: [DesignToken.Gradient]) {
        gradientGridView.subviews.forEach { $0.removeFromSuperview() }
        gradientCells.removeAll()

        let spacing: CGFloat = 12
        let cellHeight: CGFloat = 64
        let totalItems = gradients.count + 1

        var previousView: UIView?
        for index in 0..<totalItems {
            let row = index / 2
            let col = index % 2
            let isPickerButton = index == gradients.count

            let cell = UIView()
            cell.layer.cornerRadius = DesignToken.CornerRadius.card
            cell.clipsToBounds = true

            if isPickerButton {
                cell.backgroundColor = .token(.backgroundCard)
                cell.layer.borderWidth = 1
                cell.layer.borderColor = UIColor.token(.textSecondary).cgColor
                let icon = UIImageView(image: UIImage(systemName: "plus"))
                icon.tintColor = .token(.textSecondary)
                icon.contentMode = .scaleAspectFit
                cell.addSubview(icon)
                icon.snp.makeConstraints { $0.center.equalToSuperview(); $0.size.equalTo(24) }

                let tap = UITapGestureRecognizer()
                tap.rx.event
                    .subscribe(onNext: { [weak self] _ in self?.presentGradientPicker() })
                    .disposed(by: disposeBag)
                cell.addGestureRecognizer(tap)
            } else {
                let gradient = gradients[index]
                cell.applyGradient(gradient)
                cell.accessibilityIdentifier = "sahara.bgTheme.gradient.\(index)"

                let tap = UITapGestureRecognizer()
                tap.rx.event
                    .map { _ in gradient.rawValue }
                    .bind(to: gradientRelay)
                    .disposed(by: disposeBag)
                cell.addGestureRecognizer(tap)
                gradientCells.append(cell)
            }

            gradientGridView.addSubview(cell)

            cell.snp.makeConstraints { make in
                make.height.equalTo(cellHeight)
                make.top.equalToSuperview().offset(CGFloat(row) * (cellHeight + spacing))

                if col == 0 {
                    make.leading.equalToSuperview()
                    make.trailing.equalTo(gradientGridView.snp.centerX).offset(-spacing / 2)
                } else {
                    make.leading.equalTo(gradientGridView.snp.centerX).offset(spacing / 2)
                    make.trailing.equalToSuperview()
                }
            }

            previousView = cell
        }

        if let previousView {
            gradientGridView.snp.makeConstraints { make in
                make.bottom.greaterThanOrEqualTo(previousView.snp.bottom)
            }
        }
    }

    private func updatePreview(config: BackgroundConfig) {
        previewContainer.removeAllBackgroundViews()
        previewContainer.subviews.filter { $0 != previewLabel }.forEach { $0.removeFromSuperview() }
        previewContainer.backgroundColor = .clear

        switch config.theme {
        case .solidColor(let hex):
            previewContainer.backgroundColor = UIColor(hex: hex)
        case .gradient(let gradientId):
            if let gradient = DesignToken.Gradient(rawValue: gradientId) {
                previewContainer.applyGradient(gradient)
            }
        case .customGradient:
            previewContainer.applyBackgroundConfig(config)
        case .photo(let fileName):
            if let data = BackgroundThemeService.shared.loadBackgroundPhoto(fileName: fileName),
               let image = UIImage(data: data) {
                let iv = UIImageView(image: image)
                iv.contentMode = .scaleAspectFill
                iv.clipsToBounds = true
                previewContainer.insertSubview(iv, at: 0)
                iv.snp.makeConstraints { $0.edges.equalToSuperview() }
            }
        }

        if config.isDotPatternEnabled {
            previewContainer.applyDotPattern(dotSize: 3, spacing: 20, color: .token(.textOnAccent))
        }

        previewContainer.bringSubviewToFront(previewLabel)
    }

    private func updateSelection(config: BackgroundConfig) {
        colorCells.forEach { cell in
            cell.layer.borderWidth = 0
            cell.layer.borderColor = nil
        }
        gradientCells.forEach { cell in
            cell.layer.borderWidth = 0
            cell.layer.borderColor = nil
        }

        switch config.theme {
        case .solidColor(let hex):
            segmentedControl.selectedSegmentIndex = 0
            if let cell = colorCells.first(where: { $0.backgroundColor == UIColor(hex: hex) }) {
                cell.layer.borderWidth = 3
                cell.layer.borderColor = UIColor.white.cgColor
            }
        case .gradient(let gradientId):
            segmentedControl.selectedSegmentIndex = 1
            let presets = DesignToken.Gradient.backgroundPresets
            if let index = presets.firstIndex(where: { $0.rawValue == gradientId }),
               index < gradientCells.count {
                gradientCells[index].layer.borderWidth = 3
                gradientCells[index].layer.borderColor = UIColor.white.cgColor
            }
        case .customGradient:
            segmentedControl.selectedSegmentIndex = 1
        case .photo:
            segmentedControl.selectedSegmentIndex = 2
        }

        switchSelectionTab(to: segmentedControl.selectedSegmentIndex)
    }

    private func switchSelectionTab(to index: Int) {
        colorGridView.isHidden = index != 0
        gradientGridView.isHidden = index != 1
        photoSelectionView.isHidden = index != 2
        dotPatternTopConstraints.forEach { $0.deactivate() }
        dotPatternTopConstraints[index].activate()
        view.layoutIfNeeded()
    }

    private func presentSolidColorPicker() {
        let picker = UIColorPickerViewController()
        picker.supportsAlpha = false
        picker.delegate = self
        present(picker, animated: true)
    }

    private func presentGradientPicker() {
        let vc = GradientPickerViewController { [weak self] startHex, endHex in
            self?.customGradientRelay.accept((startHex, endHex))
        }
        if let sheet = vc.sheetPresentationController {
            sheet.detents = [.medium()]
            sheet.prefersGrabberVisible = true
        }
        present(vc, animated: true)
    }

    private func presentPhotoPicker() {
        var config = PHPickerConfiguration()
        config.selectionLimit = 1
        config.filter = .images

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }
}

extension BackgroundThemeViewController: UIColorPickerViewControllerDelegate {
    func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
        solidColorRelay.accept(viewController.selectedColor.toHex())
    }
}

extension BackgroundThemeViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)

        guard let provider = results.first?.itemProvider,
              provider.canLoadObject(ofClass: UIImage.self) else { return }

        provider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
            guard let image = object as? UIImage else { return }

            let maxDimension: CGFloat = 1920
            let scale = min(maxDimension / image.size.width, maxDimension / image.size.height, 1.0)
            let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)

            let renderer = UIGraphicsImageRenderer(size: newSize)
            let resized = renderer.image { _ in
                image.draw(in: CGRect(origin: .zero, size: newSize))
            }

            guard let data = resized.jpegData(compressionQuality: 0.85) else { return }

            DispatchQueue.main.async {
                self?.photoRelay.accept(data)
            }
        }
    }
}

