//
//  MediaEditorViewController.swift
//  Sahara
//
//  Created by 금가경 on 9/26/25.
//

import PencilKit
import PhotosUI
import RxCocoa
import RxSwift
import SnapKit
import UIKit

final class MediaEditorViewController: UIViewController {
    private let customNavigationBar = CustomNavigationBar()

    private let photoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = true
        imageView.backgroundColor = .clear
        return imageView
    }()

    private let canvasView: PKCanvasView = {
        let canvas = PKCanvasView()
        canvas.backgroundColor = .clear
        canvas.isOpaque = false
        canvas.drawingPolicy = .anyInput
        canvas.isUserInteractionEnabled = false
        return canvas
    }()

    private let toolBarContainer: UIView = {
        let view = UIView()
        return view
    }()

    private let toolBarScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsHorizontalScrollIndicator = false
        return scrollView
    }()

    private let modeButtonStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .equalSpacing
        stackView.spacing = 72
        return stackView
    }()

    private lazy var stickerModeButton: UIButton = {
        let button = UIButton()
        return button
    }()

    private lazy var drawingModeButton: UIButton = {
        let button = UIButton()
        return button
    }()

    private lazy var filterModeButton: UIButton = {
        let button = UIButton()
        return button
    }()

    private lazy var cropModeButton: UIButton = {
        let button = UIButton()
        return button
    }()

    private let cancelButton: UIButton = {
        let button = UIButton()
        var config = UIButton.Configuration.filled()
        config.image = UIImage(named: "xmark")
        config.baseBackgroundColor = .white
        config.baseForegroundColor = .black
        config.cornerStyle = .medium
        button.configuration = config
        return button
    }()

    private let doneButton: UIButton = {
        let button = UIButton()
        button.setTitle(NSLocalizedString("media_editor.done", comment: ""), for: .normal)
        button.titleLabel?.font = FontSystem.galmuriMono(size: 14)
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.clipsToBounds = true
        button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        return button
    }()

    private let cropOverlayView: CropOverlayView = {
        let view = CropOverlayView()
        view.isHidden = true
        return view
    }()

    private let cropApplyButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = NSLocalizedString("media_editor.apply", comment: "")
        config.baseBackgroundColor = .systemBlue
        config.baseForegroundColor = .white
        config.cornerStyle = .medium
        let button = UIButton(configuration: config)
        button.isHidden = true
        return button
    }()

    private let cropCancelButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.title = NSLocalizedString("media_editor.cancel", comment: "")
        let button = UIButton(configuration: config)
        button.isHidden = true
        return button
    }()

    private lazy var filterCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 100, height: 120)
        layout.minimumLineSpacing = 10
        layout.sectionInset = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = ColorSystem.cardBackground
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.register(FilterCell.self, forCellWithReuseIdentifier: FilterCell.identifier)
        collectionView.dataSource = self
        collectionView.layer.cornerRadius = 12
        collectionView.clipsToBounds = true
        return collectionView
    }()

    private lazy var filters: [(name: String, filter: CIFilter?)] = [
        (NSLocalizedString("filter.original", comment: ""), nil),
        (NSLocalizedString("filter.noir", comment: ""), CIFilter(name: "CIPhotoEffectNoir")),
        (NSLocalizedString("filter.sepia", comment: ""), CIFilter(name: "CISepiaTone")),
        (NSLocalizedString("filter.instant", comment: ""), CIFilter(name: "CIPhotoEffectInstant")),
        (NSLocalizedString("filter.chrome", comment: ""), CIFilter(name: "CIPhotoEffectChrome")),
        (NSLocalizedString("filter.fade", comment: ""), CIFilter(name: "CIPhotoEffectFade")),
        (NSLocalizedString("filter.mono", comment: ""), CIFilter(name: "CIPhotoEffectMono")),
        (NSLocalizedString("filter.process", comment: ""), CIFilter(name: "CIPhotoEffectProcess")),
        (NSLocalizedString("filter.transfer", comment: ""), CIFilter(name: "CIPhotoEffectTransfer")),
        (NSLocalizedString("filter.tonal", comment: ""), CIFilter(name: "CIPhotoEffectTonal"))
    ]

    private let trashIconView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "trash.fill")
        imageView.tintColor = .systemRed
        imageView.contentMode = .scaleAspectFit
        imageView.isHidden = true
        return imageView
    }()

    private let leftStarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "star")?.withRenderingMode(.alwaysTemplate)
        imageView.tintColor = UIColor(hex: "FFFFBD")
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let rightStarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "star")?.withRenderingMode(.alwaysTemplate)
        imageView.tintColor = UIColor(hex: "A0BAFF")
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let viewModel: MediaEditorViewModel
    private let disposeBag = DisposeBag()
    var onEditingComplete: ((UIImage) -> Void)?

    private var stickerViews: [DraggableStickerView] = []
    private var photoViews: [DraggableImageView] = []
    private var currentMode = BehaviorRelay<EditMode?>(value: nil)
    private let toolPicker = PKToolPicker()
    private var originalImage: UIImage?
    private var croppedImage: UIImage?
    private let context = CIContext()
    private let filterSelectedRelay = PublishRelay<(Int, UIImage?)>()
    private let cropAppliedRelay = PublishRelay<(UIImage, CGRect, CGRect)>()
    private let photoSelectedRelay = PublishRelay<UIImage>()
    private let viewWillAppearRelay = PublishRelay<Void>()

    private lazy var dragHandler = MediaEditorDragHandler(
        trashIconView: trashIconView,
        parentView: view
    )

    init(viewModel: MediaEditorViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        configureUI()
        setupCustomNavigationBar()
        setupModeButtons()
        setupPencilKit()
        bind()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        toolBarContainer.layer.sublayers?.first(where: { $0 is CAGradientLayer })?.frame = toolBarContainer.bounds
        doneButton.applyGradient(.buttonPink)
        updateStarPositions()
    }

    private func updateStarPositions() {
        guard let image = photoImageView.image else { return }

        let imageRect = MediaEditorCropHandler.calculateDisplayedImageRect(
            imageSize: image.size,
            in: photoImageView.bounds.size
        )

        let imageFrameInView = CGRect(
            x: photoImageView.frame.origin.x + imageRect.origin.x,
            y: photoImageView.frame.origin.y + imageRect.origin.y,
            width: imageRect.width,
            height: imageRect.height
        )

        leftStarImageView.snp.remakeConstraints { make in
            make.centerX.equalTo(view).offset(imageFrameInView.minX - view.bounds.width / 2)
            make.centerY.equalTo(view).offset(imageFrameInView.minY - view.bounds.height / 2)
            make.width.height.equalTo(32)
        }

        rightStarImageView.snp.remakeConstraints { make in
            make.centerX.equalTo(view).offset(imageFrameInView.maxX - view.bounds.width / 2)
            make.centerY.equalTo(view).offset(imageFrameInView.minY - view.bounds.height / 2)
            make.width.height.equalTo(32)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewWillAppearRelay.accept(())
    }

    private func setupPencilKit() {
        canvasView.tool = PKInkingTool(.pen, color: .black, width: 5)

        // PKToolPicker 초기화 시 발생하는 내부 경고 무시
        // "Missing defaults dictionary" 경고는 PencilKit 내부 동작으로 앱 기능에 영향 없음
        toolPicker.setVisible(false, forFirstResponder: canvasView)
        toolPicker.addObserver(canvasView)
        canvasView.becomeFirstResponder()

        if let window = view.window, let toolPicker = toolPicker as? PKToolPicker {
            toolPicker.frameObscured(in: window)
        }
    }

    private func bind() {
        stickerModeButton.rx.tap
            .bind(with: self) { owner, _ in
                owner.presentStickerModal()
            }
            .disposed(by: disposeBag)

        drawingModeButton.rx.tap
            .bind(with: self) { owner, _ in
                owner.currentMode.accept(.drawing)
            }
            .disposed(by: disposeBag)

        filterModeButton.rx.tap
            .bind(with: self) { owner, _ in
                owner.currentMode.accept(.filter)
            }
            .disposed(by: disposeBag)

        cropModeButton.rx.tap
            .bind(with: self) { owner, _ in
                owner.currentMode.accept(.crop)
            }
            .disposed(by: disposeBag)

        currentMode
            .bind(with: self) { owner, mode in
                owner.updateEditMode(mode: mode)
                owner.updateModeButtons(currentMode: mode)
            }
            .disposed(by: disposeBag)


        cropApplyButton.rx.tap
            .bind(with: self) { owner, _ in
                owner.applyCrop()
            }
            .disposed(by: disposeBag)

        cropCancelButton.rx.tap
            .bind(with: self) { owner, _ in
                owner.currentMode.accept(nil)
            }
            .disposed(by: disposeBag)

        let input = MediaEditorViewModel.Input(
            viewWillAppear: viewWillAppearRelay.asObservable(),
            searchQuery: .empty(),
            stickerSelected: .empty(),
            filterSelected: filterSelectedRelay.asObservable(),
            cropApplied: cropAppliedRelay.asObservable(),
            drawingChanged: Observable.just(()),
            photoSelected: photoSelectedRelay.asObservable(),
            doneButtonTapped: doneButton.rx.tap.asObservable().map { [weak self] in
                guard let self = self else { return UIImage() }
                return self.generateFinalImage()
            },
            cancelButtonTapped: cancelButton.rx.tap.asObservable()
        )

        let output = viewModel.transform(input: input)

        output.originalImage
            .drive(with: self) { owner, image in
                owner.photoImageView.image = image
                owner.originalImage = image
            }
            .disposed(by: disposeBag)

        output.currentEditingImage
            .drive(with: self) { owner, image in
                owner.photoImageView.image = image
            }
            .disposed(by: disposeBag)

        output.croppedImage
            .drive(with: self) { owner, image in
                owner.croppedImage = image
            }
            .disposed(by: disposeBag)

        output.selectedPhoto
            .drive(with: self) { owner, image in
                owner.addPhotoToCanvas(image)
            }
            .disposed(by: disposeBag)

        output.navigateToMetadata
            .drive(with: self) { owner, editedImage in
                if let callback = owner.onEditingComplete {
                    callback(editedImage)
                    owner.dismiss(animated: true)
                } else {
                    let metadataViewModel = CardInfoViewModel(editedImage: editedImage)
                    let metadataVC = CardInfoViewController(viewModel: metadataViewModel)
                    owner.navigationController?.pushViewController(metadataVC, animated: true)
                }
            }
            .disposed(by: disposeBag)

        output.dismiss
            .drive(with: self) { owner, _ in
                if let navController = owner.navigationController {
                    navController.dismiss(animated: true)
                } else {
                    owner.dismiss(animated: true)
                }
            }
            .disposed(by: disposeBag)

        filterCollectionView.rx.itemSelected
            .withUnretained(self)
            .map { owner, indexPath -> (Int, UIImage?) in
                let baseImage = owner.croppedImage ?? owner.originalImage
                return (indexPath.item, baseImage)
            }
            .bind(to: filterSelectedRelay)
            .disposed(by: disposeBag)
    }

    private func addStickerToPhoto(_ sticker: KlipySticker) {
        let stickerView = DraggableStickerView()
        stickerView.configure(with: sticker)
        stickerView.frame = CGRect(x: photoImageView.bounds.midX - 50,
                                   y: photoImageView.bounds.midY - 50,
                                   width: 100,
                                   height: 100)

        stickerView.onDragChanged = { [weak self] view in
            self?.dragHandler.handleDragChanged(view: view)
        }

        stickerView.onDragEnded = { [weak self] view in
            guard let self = self else { return }
            _ = self.dragHandler.handleDragEnded(view: view, in: &self.stickerViews)
        }

        photoImageView.addSubview(stickerView)
        stickerViews.append(stickerView)
    }

    private func addPhotoToCanvas(_ image: UIImage) {
        let imageView = DraggableImageView(frame: .zero)
        imageView.configure(with: image)
        imageView.frame = CGRect(x: photoImageView.bounds.midX - 50,
                                y: photoImageView.bounds.midY - 50,
                                width: 100,
                                height: 100)

        imageView.onDragChanged = { [weak self] view in
            self?.dragHandler.handleDragChanged(view: view)
        }

        imageView.onDragEnded = { [weak self] view in
            guard let self = self else { return }
            _ = self.dragHandler.handleDragEnded(view: view, in: &self.photoViews)
        }

        photoImageView.addSubview(imageView)
        photoViews.append(imageView)
    }


    private func updateEditMode(mode: EditMode?) {
        filterCollectionView.isHidden = true
        canvasView.isUserInteractionEnabled = false
        toolPicker.setVisible(false, forFirstResponder: canvasView)
        photoImageView.isUserInteractionEnabled = true
        cropOverlayView.isHidden = true
        cropApplyButton.isHidden = true
        cropCancelButton.isHidden = true
        toolBarContainer.isHidden = false
        doneButton.isHidden = false

        photoImageView.snp.remakeConstraints { make in
            make.top.equalTo(customNavigationBar.snp.bottom).offset(40)
            make.horizontalEdges.equalToSuperview().inset(40)
            make.bottom.equalTo(toolBarContainer.snp.top).offset(-40)
        }

        canvasView.snp.remakeConstraints { make in
            make.edges.equalTo(photoImageView)
        }

        toolBarContainer.snp.remakeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(70)
        }

        UIView.animate(withDuration: 0.3, animations: {
            self.view.layoutIfNeeded()
        })

        guard let mode = mode else {
            doneButton.isHidden = false
            return
        }

        switch mode {
        case .sticker:
            break
        case .drawing:
            canvasView.isUserInteractionEnabled = true

            toolBarContainer.snp.remakeConstraints { make in
                make.leading.trailing.equalToSuperview()
                make.height.equalTo(70)
                make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-75)
            }

            UIView.animate(withDuration: 0.3, animations: {
                self.view.layoutIfNeeded()
            })

            toolPicker.setVisible(true, forFirstResponder: canvasView)
        case .filter:
            photoImageView.snp.remakeConstraints { make in
                make.top.equalTo(customNavigationBar.snp.bottom).offset(40)
                make.horizontalEdges.equalToSuperview().inset(40)
                make.bottom.equalTo(filterCollectionView.snp.top).offset(-16)
            }

            filterCollectionView.isHidden = false

            UIView.animate(withDuration: 0.3, animations: {
                self.view.layoutIfNeeded()
            }, completion: { _ in
                self.filterCollectionView.reloadData()
                self.filterCollectionView.layoutIfNeeded()
            })
        case .photo:
            break
        case .crop:
            cropOverlayView.isHidden = false
            cropApplyButton.isHidden = false
            cropCancelButton.isHidden = false
            toolBarContainer.isHidden = true
            doneButton.isHidden = true
            guard let original = originalImage else { return }
            photoImageView.image = original
            setupCropOverlay()
        }
    }

    private func updateModeButtons(currentMode: EditMode?) {
        let buttons = [stickerModeButton, drawingModeButton, filterModeButton, cropModeButton]
        let modes: [EditMode?] = [.sticker, .drawing, .filter, .crop]

        for (button, mode) in zip(buttons, modes) {
            if mode == currentMode {
                button.alpha = 1.0
            } else {
                button.alpha = 0.5
            }
        }
    }

    private func presentStickerModal() {
        let stickerModalVC = StickerModalViewController(viewModel: viewModel)
        stickerModalVC.onStickerSelected = { [weak self] sticker in
            self?.addStickerToPhoto(sticker)
        }

        let navController = UINavigationController(rootViewController: stickerModalVC)
        if let sheet = navController.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
        }
        present(navController, animated: true)
    }


    private func generateFinalImage() -> UIImage {
        guard let baseImage = photoImageView.image else {
            return UIImage()
        }

        toolBarContainer.isHidden = true

        let imageRect = MediaEditorCropHandler.calculateDisplayedImageRect(
            imageSize: baseImage.size,
            in: photoImageView.bounds.size
        )

        let renderer = UIGraphicsImageRenderer(size: imageRect.size)
        let image = renderer.image { context in
            context.cgContext.translateBy(x: -imageRect.origin.x, y: -imageRect.origin.y)
            photoImageView.layer.render(in: context.cgContext)

            let drawingImage = canvasView.drawing.image(from: canvasView.bounds, scale: UIScreen.main.scale)
            drawingImage.draw(at: .zero)
        }

        toolBarContainer.isHidden = false

        return image
    }

    private func presentPhotoPicker() {
        var configuration = PHPickerConfiguration()
        configuration.selectionLimit = 1
        configuration.filter = .images
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
    }

    private func setupCropOverlay() {
        guard let currentImage = photoImageView.image else { return }

        let imageRect = MediaEditorCropHandler.calculateDisplayedImageRect(
            imageSize: currentImage.size,
            in: photoImageView.bounds.size
        )

        cropOverlayView.frame = photoImageView.bounds
        cropOverlayView.setCropRect(imageRect)
    }

    private func applyCrop() {
        guard let currentImage = photoImageView.image else { return }

        let cropRect = cropOverlayView.cropRect
        let displayedImageRect = MediaEditorCropHandler.calculateDisplayedImageRect(
            imageSize: currentImage.size,
            in: photoImageView.bounds.size
        )

        cropAppliedRelay.accept((currentImage, cropRect, displayedImageRect))
        currentMode.accept(nil)
    }

    private func setupCustomNavigationBar() {
        customNavigationBar.configure(title: NSLocalizedString("media_editor.title", comment: ""))
        customNavigationBar.hideLeftButton()

        view.addSubview(cancelButton)
        view.addSubview(doneButton)

        cancelButton.snp.makeConstraints { make in
            make.leading.equalTo(customNavigationBar).offset(16)
            make.centerY.equalTo(customNavigationBar)
            make.width.equalTo(48)
            make.height.equalTo(44)
        }

        doneButton.snp.makeConstraints { make in
            make.trailing.equalTo(customNavigationBar).inset(16)
            make.centerY.equalTo(customNavigationBar)
            make.width.greaterThanOrEqualTo(48)
            make.height.equalTo(44)
        }
    }

    private func setupModeButtons() {
        let buttonConfigs: [(button: UIButton, imageName: String, titleKey: String)] = [
            (stickerModeButton, "sticker", "media_editor.sticker"),
            (drawingModeButton, "edit", "media_editor.drawing"),
            (filterModeButton, "sliders", "media_editor.filter"),
            (cropModeButton, "crop", "media_editor.crop")
        ]

        for config in buttonConfigs {
            let stack = UIStackView()
            stack.axis = .vertical
            stack.alignment = .center
            stack.spacing = 4
            stack.isUserInteractionEnabled = false

            let imageView = UIImageView()
            if let originalImage = UIImage(named: config.imageName) {
                imageView.image = originalImage.withRenderingMode(.alwaysTemplate)
            }
            imageView.contentMode = .scaleAspectFit
            imageView.tintColor = .black

            let label = UILabel()
            let text = NSLocalizedString(config.titleKey, comment: "")
            let attributedString = text.attributedString(
                font: FontSystem.galmuriMono(size: 12),
                letterSpacing: -6,
                color: .black
            )
            label.attributedText = attributedString
            label.textAlignment = .center

            stack.addArrangedSubview(imageView)
            stack.addArrangedSubview(label)

            imageView.snp.makeConstraints { make in
                make.width.height.equalTo(24)
            }

            config.button.addSubview(stack)
            stack.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }

            modeButtonStackView.addArrangedSubview(config.button)
        }
    }

    private func configureUI() {
        view.applyGradient(.cardInfoBackground)

        view.addSubview(customNavigationBar)
        view.addSubview(photoImageView)
        view.addSubview(canvasView)
        view.addSubview(toolBarContainer)
        view.addSubview(filterCollectionView)
        view.addSubview(trashIconView)
        view.addSubview(cropOverlayView)
        view.addSubview(cropApplyButton)
        view.addSubview(cropCancelButton)
        view.addSubview(leftStarImageView)
        view.addSubview(rightStarImageView)

        toolBarContainer.addSubview(toolBarScrollView)
        toolBarScrollView.addSubview(modeButtonStackView)

        toolBarContainer.applyGradient(.barBack)

        customNavigationBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.horizontalEdges.equalToSuperview()
            make.height.equalTo(54)
        }

        toolBarContainer.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(70)
        }

        toolBarScrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        modeButtonStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 8, left: 20, bottom: 8, right: 20))
            make.height.equalTo(54)
        }

        photoImageView.snp.makeConstraints { make in
            make.top.equalTo(customNavigationBar.snp.bottom).offset(40)
            make.horizontalEdges.equalToSuperview().inset(40)
            make.bottom.equalTo(toolBarContainer.snp.top).offset(-40)
        }


        canvasView.snp.makeConstraints { make in
            make.edges.equalTo(photoImageView)
        }

        filterCollectionView.snp.makeConstraints { make in
            make.bottom.equalTo(toolBarContainer.snp.top).offset(-20)
            make.horizontalEdges.equalToSuperview().inset(40)
            make.height.equalTo(144)
        }

        trashIconView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(toolBarContainer.snp.top).offset(-20)
            make.width.height.equalTo(60)
        }

        cropOverlayView.snp.makeConstraints { make in
            make.edges.equalTo(photoImageView)
        }

        cropApplyButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(20)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-10)
            make.width.equalTo(100)
            make.height.equalTo(50)
        }

        cropCancelButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(20)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-10)
            make.width.equalTo(100)
            make.height.equalTo(50)
        }
    }
}

extension MediaEditorViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == filterCollectionView {
            return filters.count
        }
        return 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == filterCollectionView {
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: FilterCell.identifier,
                for: indexPath
            ) as? FilterCell else {
                return UICollectionViewCell()
            }

            let filterItem = filters[indexPath.item]
            cell.configure(with: filterItem.name, image: originalImage, filter: filterItem.filter, context: context)
            return cell
        }
        return UICollectionViewCell()
    }
}

extension MediaEditorViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)

        guard let itemProvider = results.first?.itemProvider else { return }

        if itemProvider.canLoadObject(ofClass: UIImage.self) {
            itemProvider.loadObject(ofClass: UIImage.self) { [weak self] image, _ in
                DispatchQueue.main.async {
                    guard let image = image as? UIImage else { return }
                    self?.photoSelectedRelay.accept(image)
                }
            }
        }
    }
}
