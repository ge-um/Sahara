//
//  MediaEditorViewController.swift
//  Sahara
//
//  Created by 금가경 on 9/26/25.
//

import OSLog
import PencilKit
import PhotosUI
import RxCocoa
import RxSwift
import SnapKit
import UIKit

final class MediaEditorViewController: UIViewController {
    let customNavigationBar = CustomNavigationBar()
    let photoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = false
        imageView.backgroundColor = .clear
        return imageView
    }()

    let canvasView: PKCanvasView = {
        let canvas = PKCanvasView()
        canvas.backgroundColor = .clear
        canvas.isOpaque = false
        canvas.drawingPolicy = .anyInput
        canvas.isUserInteractionEnabled = false
        return canvas
    }()

    let stickerContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = true
        return view
    }()

    let toolBarContainer: UIView = {
        let view = UIView()
        return view
    }()

    let toolBarScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsHorizontalScrollIndicator = false
        return scrollView
    }()

    let modeButtonStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .equalSpacing
        stackView.spacing = 52
        return stackView
    }()

    lazy var stickerModeButton: UIButton = {
        let button = UIButton()
        return button
    }()

    lazy var drawingModeButton: UIButton = {
        let button = UIButton()
        return button
    }()

    lazy var filterModeButton: UIButton = {
        let button = UIButton()
        return button
    }()

    lazy var photoModeButton: UIButton = {
        let button = UIButton()
        return button
    }()

    lazy var cropModeButton: UIButton = {
        let button = UIButton()
        return button
    }()

    lazy var undoButton: UIButton = {
        let button = UIButton()
        var config = UIButton.Configuration.plain()
        config.image = UIImage(named: "cornerUpLeft")?.withRenderingMode(.alwaysTemplate)
        config.baseForegroundColor = .black
        config.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)

        button.configuration = config
        button.backgroundColor = UIColor.white.withAlphaComponent(0.8)
        button.layer.cornerRadius = 18
        button.clipsToBounds = true
        button.isHidden = true
        button.isEnabled = false
        button.alpha = 0.5
        return button
    }()

    lazy var redoButton: UIButton = {
        let button = UIButton()
        var config = UIButton.Configuration.plain()
        config.image = UIImage(named: "cornerUpRight")?.withRenderingMode(.alwaysTemplate)
        config.baseForegroundColor = .black
        config.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)

        button.configuration = config
        button.backgroundColor = UIColor.white.withAlphaComponent(0.8)
        button.layer.cornerRadius = 18
        button.clipsToBounds = true
        button.isHidden = true
        button.isEnabled = false
        button.alpha = 0.5
        return button
    }()

    let cancelButton: UIButton = {
        let button = UIButton()
        var config = UIButton.Configuration.filled()
        config.image = UIImage(named: "xmark")
        config.baseBackgroundColor = .white
        config.baseForegroundColor = .black
        config.cornerStyle = .medium
        button.configuration = config
        return button
    }()

    let doneButton: UIButton = {
        let button = UIButton()
        var config = UIButton.Configuration.filled()
        config.title = NSLocalizedString("media_editor.done", comment: "")
        config.baseBackgroundColor = .clear
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

    let cropOverlayView: CropOverlayView = {
        let view = CropOverlayView()
        view.isHidden = true
        view.backgroundColor = .clear
        return view
    }()

    let cropApplyButton: UIButton = {
        let button = UIButton()
        var config = UIButton.Configuration.filled()
        config.title = NSLocalizedString("media_editor.apply", comment: "")
        config.baseBackgroundColor = .clear
        config.baseForegroundColor = .white
        config.cornerStyle = .medium
        config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)

        var titleAttr = AttributeContainer()
        titleAttr.font = FontSystem.galmuriMono(size: 14)
        config.attributedTitle = AttributedString(config.title ?? "", attributes: titleAttr)

        button.configuration = config
        button.layer.cornerRadius = 8
        button.clipsToBounds = true
        button.isHidden = true
        return button
    }()

    let cropCancelButton: UIButton = {
        let button = UIButton()
        var config = UIButton.Configuration.filled()
        config.title = NSLocalizedString("media_editor.cancel", comment: "")
        config.baseBackgroundColor = .white
        config.baseForegroundColor = .black
        config.cornerStyle = .medium
        config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)

        var titleAttr = AttributeContainer()
        titleAttr.font = FontSystem.galmuriMono(size: 14)
        config.attributedTitle = AttributedString(config.title ?? "", attributes: titleAttr)

        button.configuration = config
        button.layer.cornerRadius = 8
        button.clipsToBounds = true
        button.isHidden = true
        return button
    }()

    let filterContainerView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = DesignToken.CornerRadius.card
        view.clipsToBounds = true
        view.isHidden = true
        return view
    }()

    lazy var filterCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 100, height: 120)
        layout.minimumLineSpacing = 10
        layout.sectionInset = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.register(FilterCell.self, forCellWithReuseIdentifier: FilterCell.identifier)
        collectionView.dataSource = self
        return collectionView
    }()

    let trashIconView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "trash")?.withRenderingMode(.alwaysTemplate)
        imageView.tintColor = .white
        imageView.contentMode = .scaleAspectFit
        imageView.isHidden = true
        return imageView
    }()

    let cropDimOverlay: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        view.isHidden = true
        view.isUserInteractionEnabled = false
        return view
    }()

    let leftStarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "star")?.withRenderingMode(.alwaysTemplate)
        imageView.tintColor = UIColor(hex: "FFFFBD")
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    let rightStarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "star")?.withRenderingMode(.alwaysTemplate)
        imageView.tintColor = UIColor(hex: "A0BAFF")
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    let viewModel: MediaEditorViewModel
    weak var coordinator: MediaEditorCoordinatorProtocol?
    private let disposeBag = DisposeBag()

    let currentMode = BehaviorRelay<EditMode?>(value: nil)
    let drawingToolStrip = DrawingToolStrip()

    private var stickerViews: [DraggableStickerView] = []
    private var photoViews: [DraggableImageView] = []
    private var selectedView: BaseGestureView?

    var cachedUncroppedOriginalImage: UIImage?
    var lastCropRect: CGRect?
    private var cachedOriginalImageForFilter: UIImage?
    private var currentFilterIndex: Int = 0
    private var initialImageFormat: ImageSourceData.ImageFormat?
    private var initialOriginalData: Data?

    private let filterHandler = MediaEditorFilterHandler()
    private lazy var dragHandler = MediaEditorDragHandler(
        trashIconView: trashIconView,
        parentView: view
    )

    private let viewWillAppearRelay = PublishRelay<Void>()
    private let filterSelectedRelay = PublishRelay<(Int, UIImage?)>()
    let photoSelectedRelay = PublishRelay<UIImage>()
    private let stickerButtonTappedRelay = PublishRelay<Void>()
    private let stickerAddedRelay = PublishRelay<(sticker: KlipySticker, position: CGPoint, scale: CGFloat)>()
    private let drawingChangedRelay = PublishRelay<Void>()

    private var hasInitialized = false

    private var usedTools: Set<String> = []

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
        setupGlobalGestures()
        bind()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        doneButton.applyGradient(.ctaPink)
        cropApplyButton.applyGradient(.ctaPink)
        updateStarPositions()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewWillAppearRelay.accept(())
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        guard let image = photoImageView.image else { return }
        let oldViewSize = photoImageView.bounds.size
        guard oldViewSize.width > 0, oldViewSize.height > 0 else { return }

        let savedPositions = captureOverlayPositions(imageSize: image.size, viewSize: oldViewSize)
        let oldDisplayRect = ImageCoordinateSpace.displayRect(imageSize: image.size, in: oldViewSize)
        let shouldTransformDrawing = !canvasView.drawing.strokes.isEmpty

        coordinator.animate(alongsideTransition: nil) { [weak self] _ in
            guard let self = self, let currentImage = self.photoImageView.image else { return }
            let newViewSize = self.photoImageView.bounds.size
            guard newViewSize != oldViewSize else { return }

            let newDisplayRect = ImageCoordinateSpace.displayRect(imageSize: currentImage.size, in: newViewSize)
            let scaleRatio = newDisplayRect.width / oldDisplayRect.width
            self.restoreOverlayPositions(savedPositions, imageSize: currentImage.size, viewSize: newViewSize, scaleRatio: scaleRatio)

            if shouldTransformDrawing {
                self.transformDrawing(from: oldDisplayRect, to: newDisplayRect)
            }

            if self.currentMode.value == .crop {
                self.setupCropOverlay()
            }
        }
    }

    private func setupPencilKit() {
        canvasView.tool = PKInkingTool(.pen, color: .black, width: 5)
        canvasView.delegate = self
        setupDrawingToolStrip()
    }

    private func setupDrawingToolStrip() {
        drawingToolStrip.onToolChanged = { [weak self] tool in
            self?.canvasView.tool = tool
        }

        drawingToolStrip.onCustomColorRequested = { [weak self] in
            let picker = UIColorPickerViewController()
            picker.delegate = self
            picker.supportsAlpha = false
            self?.present(picker, animated: true)
        }

        drawingToolStrip.onUndoTapped = { [weak self] in
            self?.canvasView.undoManager?.undo()
            self?.updateUndoRedoButtons()
        }

        drawingToolStrip.onRedoTapped = { [weak self] in
            self?.canvasView.undoManager?.redo()
            self?.updateUndoRedoButtons()
        }
    }

    private func setupGlobalGestures() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handleGlobalPan))
        panGesture.delegate = self
        stickerContainerView.addGestureRecognizer(panGesture)

        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handleGlobalPinch))
        pinchGesture.delegate = self
        stickerContainerView.addGestureRecognizer(pinchGesture)

        let rotationGesture = UIRotationGestureRecognizer(target: self, action: #selector(handleGlobalRotation))
        rotationGesture.delegate = self
        stickerContainerView.addGestureRecognizer(rotationGesture)
    }

    @objc private func handleGlobalPan(_ gesture: UIPanGestureRecognizer) {
        guard let selectedView = selectedView, selectedView.isSelected else { return }

        let translation = gesture.translation(in: stickerContainerView)
        selectedView.applyPanTranslation(translation)
        gesture.setTranslation(.zero, in: stickerContainerView)

        switch gesture.state {
        case .changed:
            dragHandler.handleDragChanged(view: selectedView)
        case .ended, .cancelled:
            if let stickerView = selectedView as? DraggableStickerView {
                _ = dragHandler.handleDragEnded(view: stickerView, in: &stickerViews)
            } else if let photoView = selectedView as? DraggableImageView {
                _ = dragHandler.handleDragEnded(view: photoView, in: &photoViews)
            }
        default:
            break
        }
    }

    @objc private func handleGlobalPinch(_ gesture: UIPinchGestureRecognizer) {
        guard let selectedView = selectedView, selectedView.isSelected else { return }

        if gesture.state == .began || gesture.state == .changed {
            selectedView.applyPinchScale(gesture.scale)
            gesture.scale = 1.0
        }
    }

    @objc private func handleGlobalRotation(_ gesture: UIRotationGestureRecognizer) {
        guard let selectedView = selectedView, selectedView.isSelected else { return }

        if gesture.state == .began || gesture.state == .changed {
            selectedView.applyRotation(gesture.rotation)
            gesture.rotation = 0
        }
    }

    private func bind() {
        bindModeButtons()
        bindCropButtons()
        bindUndoRedo()
        bindViewModel()
    }

    private func bindModeButtons() {
        stickerModeButton.rx.tap
            .do(onNext: { [weak self] _ in
                guard let self = self, self.currentMode.value != .sticker else { return }
                self.usedTools.insert("sticker")
                AnalyticsService.shared.logPhotoEditToolUsed(tool: "sticker")
            })
            .bind(with: self) { owner, _ in
                if owner.currentMode.value == .sticker {
                    owner.currentMode.accept(nil)
                } else {
                    owner.stickerButtonTappedRelay.accept(())
                }
            }
            .disposed(by: disposeBag)

        drawingModeButton.rx.tap
            .do(onNext: { [weak self] _ in
                guard let self = self, self.currentMode.value != .drawing else { return }
                self.usedTools.insert("drawing")
                AnalyticsService.shared.logPhotoEditToolUsed(tool: "drawing")
            })
            .bind(with: self) { owner, _ in
                if owner.currentMode.value == .drawing {
                    owner.currentMode.accept(nil)
                } else {
                    owner.currentMode.accept(.drawing)
                }
            }
            .disposed(by: disposeBag)

        filterModeButton.rx.tap
            .do(onNext: { [weak self] _ in
                guard let self = self, self.currentMode.value != .filter else { return }
                self.usedTools.insert("filter")
                AnalyticsService.shared.logPhotoEditToolUsed(tool: "filter")
            })
            .bind(with: self) { owner, _ in
                if owner.currentMode.value == .filter {
                    owner.currentMode.accept(nil)
                } else {
                    owner.currentMode.accept(.filter)
                }
            }
            .disposed(by: disposeBag)

        photoModeButton.rx.tap
            .do(onNext: { [weak self] _ in
                guard let self = self, self.currentMode.value != .photo else { return }
                self.usedTools.insert("photo")
                AnalyticsService.shared.logPhotoEditToolUsed(tool: "photo")
            })
            .bind(with: self) { owner, _ in
                if owner.currentMode.value == .photo {
                    owner.currentMode.accept(nil)
                } else {
                    owner.currentMode.accept(.photo)
                }
            }
            .disposed(by: disposeBag)

        cropModeButton.rx.tap
            .do(onNext: { [weak self] _ in
                guard let self = self, self.currentMode.value != .crop else { return }
                self.usedTools.insert("crop")
                AnalyticsService.shared.logPhotoEditToolUsed(tool: "crop")
            })
            .bind(with: self) { owner, _ in
                if owner.currentMode.value == .crop {
                    owner.currentMode.accept(nil)
                } else {
                    owner.currentMode.accept(.crop)
                }
            }
            .disposed(by: disposeBag)

        currentMode
            .bind(with: self) { owner, mode in
                owner.updateEditMode(mode: mode)
                owner.updateModeButtons(currentMode: mode)
            }
            .disposed(by: disposeBag)
    }

    private func bindCropButtons() {
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
    }

    private func bindUndoRedo() {
        undoButton.rx.tap
            .bind(with: self) { owner, _ in
                owner.canvasView.undoManager?.undo()
                owner.updateUndoRedoButtons()
            }
            .disposed(by: disposeBag)

        redoButton.rx.tap
            .bind(with: self) { owner, _ in
                owner.canvasView.undoManager?.redo()
                owner.updateUndoRedoButtons()
            }
            .disposed(by: disposeBag)
    }

    private func bindViewModel() {
        let input = MediaEditorViewModel.Input(
            viewWillAppear: viewWillAppearRelay.asObservable(),
            stickerButtonTapped: stickerButtonTappedRelay.asObservable(),
            searchQuery: .empty(),
            loadMoreTrigger: .empty(),
            stickerSelected: .empty(),
            stickerAdded: stickerAddedRelay.asObservable(),
            filterSelected: filterSelectedRelay.asObservable(),
            cropApplied: .never(),
            drawingChanged: drawingChangedRelay.asObservable(),
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
                owner.cachedOriginalImageForFilter = image

                guard !owner.hasInitialized else { return }
                owner.hasInitialized = true

                owner.initialImageFormat = output.initialImageFormat
                owner.initialOriginalData = output.initialOriginalData

                if let initialUncroppedImage = output.initialUncroppedImage {
                    owner.cachedUncroppedOriginalImage = initialUncroppedImage
                }
                if let initialCropRect = output.initialCropRect {
                    owner.lastCropRect = initialCropRect
                }

                if !output.initialStickers.isEmpty {
                    DispatchQueue.main.async {
                        owner.view.layoutIfNeeded()
                        owner.restoreInitialStickers(output.initialStickers, on: image)
                    }
                }

                if let drawingData = output.initialDrawingData {
                    owner.restoreDrawing(from: drawingData)
                }

                if let filterIndex = output.initialFilterIndex, filterIndex > 0 {
                    owner.currentFilterIndex = filterIndex
                    DispatchQueue.main.async {
                        owner.restoreFilterSelection(index: filterIndex)
                    }
                }
            }
            .disposed(by: disposeBag)

        output.uncroppedOriginalImage
            .drive(with: self) { owner, image in
                owner.cachedUncroppedOriginalImage = image
            }
            .disposed(by: disposeBag)

        output.currentEditingImage
            .drive(with: self) { owner, image in
                owner.photoImageView.image = image
            }
            .disposed(by: disposeBag)

        output.selectedPhoto
            .drive(with: self) { owner, image in
                owner.addPhotoToCanvas(image)
            }
            .disposed(by: disposeBag)

        output.navigateToMetadata
            .do(onNext: { [weak self] _ in
                guard let self = self else { return }
                AnalyticsService.shared.logPhotoEditComplete(toolsUsedCount: self.usedTools.count)
            })
            .drive(with: self) { owner, _ in
                let (displayImage, metadata) = owner.prepareEditResult()
                Logger.mediaEditor.info("Finishing edit: stickers=\(metadata.stickers.count), filter=\(metadata.filterIndex ?? 0)")
                owner.coordinator?.finishEditing(displayImage: displayImage, metadata: metadata)
            }
            .disposed(by: disposeBag)

        output.dismiss
            .drive(with: self) { owner, _ in
                owner.coordinator?.cancelEditing()
            }
            .disposed(by: disposeBag)

        output.errorMessage
            .drive(with: self) { owner, message in
                if !message.isEmpty {
                    owner.showToast(message: message)
                }
            }
            .disposed(by: disposeBag)

        output.networkErrorMessage
            .drive(with: self) { owner, message in
                if !message.isEmpty {
                    owner.showToast(message: message)
                }
            }
            .disposed(by: disposeBag)

        output.shouldShowStickerModal
            .drive(with: self) { owner, _ in
                owner.currentMode.accept(.sticker)
                owner.presentStickerModal()
            }
            .disposed(by: disposeBag)

        filterCollectionView.rx.itemSelected
            .withUnretained(self)
            .map { owner, indexPath -> (Int, UIImage?) in
                owner.currentFilterIndex = indexPath.item
                return (indexPath.item, owner.cachedOriginalImageForFilter)
            }
            .bind(to: filterSelectedRelay)
            .disposed(by: disposeBag)
    }

    func addStickerToPhoto(_ sticker: KlipySticker) {
        let stickerView = DraggableStickerView()
        stickerView.configure(with: sticker)
        configureStickerGestureCallbacks(for: stickerView)

        stickerContainerView.addSubview(stickerView)

        let centerX = stickerContainerView.bounds.midX
        let centerY = stickerContainerView.bounds.midY
        stickerView.frame = CGRect(x: centerX - 50, y: centerY - 50, width: 100, height: 100)

        stickerViews.append(stickerView)
        selectView(stickerView)

        let position = CGPoint(x: centerX, y: centerY)
        let scale: CGFloat = 1.0
        stickerAddedRelay.accept((sticker: sticker, position: position, scale: scale))
    }

    func addPhotoToCanvas(_ image: UIImage) {
        let imageView = DraggableImageView(frame: .zero)
        imageView.configure(with: image)
        configurePhotoGestureCallbacks(for: imageView)

        stickerContainerView.addSubview(imageView)

        let centerX = stickerContainerView.bounds.midX
        let centerY = stickerContainerView.bounds.midY
        imageView.frame = CGRect(x: centerX - 50, y: centerY - 50, width: 100, height: 100)

        photoViews.append(imageView)
        selectView(imageView)
    }

    private func generateFinalImage() -> UIImage {
        toolBarContainer.isHidden = true
        let image = MediaEditorImageHandler.generateFinalImage(
            photoImageView: photoImageView,
            stickerContainerView: stickerContainerView,
            canvasView: canvasView
        )
        toolBarContainer.isHidden = false
        return image
    }

    private func transformOverlaysForCrop(
        fromImageSize oldImageSize: CGSize,
        toImageSize newImageSize: CGSize,
        pixelOffset: CGPoint
    ) {
        let viewSize = photoImageView.bounds.size
        let oldDisplayRect = ImageCoordinateSpace.displayRect(imageSize: oldImageSize, in: viewSize)
        let newDisplayRect = ImageCoordinateSpace.displayRect(imageSize: newImageSize, in: viewSize)

        let oldPointsPerPixel = oldDisplayRect.width / oldImageSize.width
        let newPointsPerPixel = newDisplayRect.width / newImageSize.width
        let scaleRatio = newPointsPerPixel / oldPointsPerPixel

        func reposition(_ view: BaseGestureView) {
            let oldPixels = ImageCoordinateSpace.toImagePixels(
                displayCenter: view.center,
                imageSize: oldImageSize,
                displayRect: oldDisplayRect
            )
            let newPixels = CGPoint(x: oldPixels.x + pixelOffset.x, y: oldPixels.y + pixelOffset.y)
            view.center = ImageCoordinateSpace.toDisplayCenter(
                imagePixels: newPixels,
                imageSize: newImageSize,
                displayRect: newDisplayRect
            )
            if scaleRatio != 1.0 {
                view.transform = view.transform.scaledBy(x: scaleRatio, y: scaleRatio)
            }
        }

        stickerViews.forEach { reposition($0) }
        photoViews.forEach { reposition($0) }

        guard !canvasView.drawing.strokes.isEmpty else { return }

        let drawingTransform = CGAffineTransform(translationX: -oldDisplayRect.origin.x, y: -oldDisplayRect.origin.y)
            .concatenating(CGAffineTransform(
                scaleX: oldImageSize.width / oldDisplayRect.width,
                y: oldImageSize.height / oldDisplayRect.height
            ))
            .concatenating(CGAffineTransform(translationX: pixelOffset.x, y: pixelOffset.y))
            .concatenating(CGAffineTransform(
                scaleX: newDisplayRect.width / newImageSize.width,
                y: newDisplayRect.height / newImageSize.height
            ))
            .concatenating(CGAffineTransform(translationX: newDisplayRect.origin.x, y: newDisplayRect.origin.y))

        canvasView.drawing = canvasView.drawing.transformed(using: drawingTransform)
    }

    func applyCroppedImage(from uncropped: UIImage, cropRect: CGRect) {
        guard let croppedImage = MediaEditorImageHandler.cropImage(uncropped, to: cropRect) else { return }

        let offset = CGPoint(x: -cropRect.origin.x, y: -cropRect.origin.y)
        transformOverlaysForCrop(fromImageSize: uncropped.size, toImageSize: croppedImage.size, pixelOffset: offset)

        if currentFilterIndex > 0,
           let filtered = filterHandler.applyFilter(at: currentFilterIndex, to: croppedImage) {
            photoImageView.image = filtered
        } else {
            photoImageView.image = croppedImage
        }
        cachedOriginalImageForFilter = croppedImage
    }

    func expandToUncropped() {
        guard let uncropped = cachedUncroppedOriginalImage,
              let cropRect = lastCropRect,
              let currentImage = photoImageView.image else { return }

        let offset = CGPoint(x: cropRect.origin.x, y: cropRect.origin.y)
        transformOverlaysForCrop(fromImageSize: currentImage.size, toImageSize: uncropped.size, pixelOffset: offset)

        if currentFilterIndex > 0,
           let filteredUncropped = filterHandler.applyFilter(at: currentFilterIndex, to: uncropped) {
            photoImageView.image = filteredUncropped
        } else {
            photoImageView.image = uncropped
        }
    }

    private func captureOverlayPositions(imageSize: CGSize, viewSize: CGSize) -> [(BaseGestureView, CGPoint)] {
        let displayRect = ImageCoordinateSpace.displayRect(imageSize: imageSize, in: viewSize)
        guard displayRect.width > 0, displayRect.height > 0 else { return [] }

        return (stickerViews as [BaseGestureView] + photoViews).map { view in
            let pixels = ImageCoordinateSpace.toImagePixels(
                displayCenter: view.center,
                imageSize: imageSize,
                displayRect: displayRect
            )
            return (view, pixels)
        }
    }

    private func restoreOverlayPositions(_ positions: [(BaseGestureView, CGPoint)], imageSize: CGSize, viewSize: CGSize, scaleRatio: CGFloat = 1.0) {
        let displayRect = ImageCoordinateSpace.displayRect(imageSize: imageSize, in: viewSize)
        guard displayRect.width > 0, displayRect.height > 0 else { return }

        for (view, pixels) in positions {
            view.center = ImageCoordinateSpace.toDisplayCenter(
                imagePixels: pixels,
                imageSize: imageSize,
                displayRect: displayRect
            )
            if scaleRatio != 1.0 {
                view.transform = view.transform.scaledBy(x: scaleRatio, y: scaleRatio)
            }
        }
    }

    private func transformDrawing(from oldRect: CGRect, to newRect: CGRect) {
        let transform = CGAffineTransform(translationX: -oldRect.origin.x, y: -oldRect.origin.y)
            .concatenating(CGAffineTransform(scaleX: newRect.width / oldRect.width,
                                             y: newRect.height / oldRect.height))
            .concatenating(CGAffineTransform(translationX: newRect.origin.x, y: newRect.origin.y))
        canvasView.drawing = canvasView.drawing.transformed(using: transform)
    }

    func updateUndoRedoButtons() {
        guard currentMode.value == .drawing else { return }

        let canUndo = canvasView.undoManager?.canUndo ?? false
        let canRedo = canvasView.undoManager?.canRedo ?? false
        drawingToolStrip.updateUndoRedoState(canUndo: canUndo, canRedo: canRedo)
    }

    private func selectView(_ view: BaseGestureView) {
        selectedView?.isSelected = false
        selectedView = view
        view.isSelected = true
    }

    private func configureStickerGestureCallbacks(for stickerView: DraggableStickerView) {
        stickerView.onDragChanged = { [weak self] view in
            self?.dragHandler.handleDragChanged(view: view)
        }
        stickerView.onDragEnded = { [weak self] view in
            guard let self = self else { return }
            _ = self.dragHandler.handleDragEnded(view: view, in: &self.stickerViews)
        }
        stickerView.onTapped = { [weak self] tappedView in
            self?.selectView(tappedView)
        }
    }

    private func configurePhotoGestureCallbacks(for imageView: DraggableImageView) {
        imageView.onDragChanged = { [weak self] view in
            self?.dragHandler.handleDragChanged(view: view)
        }
        imageView.onDragEnded = { [weak self] view in
            guard let self = self else { return }
            _ = self.dragHandler.handleDragEnded(view: view, in: &self.photoViews)
        }
        imageView.onTapped = { [weak self] tappedView in
            self?.selectView(tappedView)
        }
    }

    private func deselectAll() {
        selectedView?.isSelected = false
        selectedView = nil
    }

    private func restoreDrawing(from data: Data) {
        do {
            let drawing = try PKDrawing(data: data)
            canvasView.drawing = drawing
            Logger.mediaEditor.info("Restored drawing")
        } catch {
            Logger.mediaEditor.error("Failed to restore drawing: \(error.localizedDescription)")
        }
    }

    private func restoreFilterSelection(index: Int) {
        let indexPath = IndexPath(item: index, section: 0)
        filterCollectionView.selectItem(at: indexPath, animated: false, scrollPosition: .centeredHorizontally)
        filterSelectedRelay.accept((index, cachedOriginalImageForFilter))
        Logger.mediaEditor.info("Restored filter selection: \(index)")
    }

    private func restoreInitialStickers(_ stickers: [StickerDTO], on image: UIImage) {
        guard !stickers.isEmpty else { return }

        let displayRect = ImageCoordinateSpace.displayRect(
            imageSize: image.size,
            in: photoImageView.bounds.size
        )

        guard displayRect.width > 0, displayRect.height > 0 else { return }

        for stickerDTO in stickers {
            if stickerDTO.sourceType == .kilpy {
                restoreKlipySticker(stickerDTO, imageSize: image.size, displayRect: displayRect)
            } else if stickerDTO.sourceType == .photo {
                restorePhotoSticker(stickerDTO, imageSize: image.size, displayRect: displayRect)
            }
        }

        Logger.mediaEditor.info("Restored \(stickers.count) stickers")
    }

    private func restoreKlipySticker(_ stickerDTO: StickerDTO, imageSize: CGSize, displayRect: CGRect) {
        let stickerView = DraggableStickerView()
        stickerView.configure(with: stickerDTO)
        configureStickerGestureCallbacks(for: stickerView)

        stickerContainerView.addSubview(stickerView)

        let center = ImageCoordinateSpace.toDisplayCenter(
            imagePixels: CGPoint(x: stickerDTO.x, y: stickerDTO.y),
            imageSize: imageSize,
            displayRect: displayRect
        )
        let baseStickerSize: CGFloat = 100

        stickerView.frame = CGRect(
            x: center.x - baseStickerSize / 2,
            y: center.y - baseStickerSize / 2,
            width: baseStickerSize,
            height: baseStickerSize
        )
        stickerView.transform = CGAffineTransform(scaleX: stickerDTO.scale, y: stickerDTO.scale)
            .rotated(by: stickerDTO.rotation)

        stickerViews.append(stickerView)
    }

    private func restorePhotoSticker(_ stickerDTO: StickerDTO, imageSize: CGSize, displayRect: CGRect) {
        guard let localFilePath = stickerDTO.localFilePath else { return }

        let fileURL = URL(fileURLWithPath: localFilePath)
        guard let photoImage = UIImage(contentsOfFile: fileURL.path) else { return }

        let imageView = DraggableImageView(frame: .zero)
        imageView.configure(with: photoImage)
        configurePhotoGestureCallbacks(for: imageView)

        stickerContainerView.addSubview(imageView)

        let center = ImageCoordinateSpace.toDisplayCenter(
            imagePixels: CGPoint(x: stickerDTO.x, y: stickerDTO.y),
            imageSize: imageSize,
            displayRect: displayRect
        )
        let baseStickerSize: CGFloat = 100

        imageView.frame = CGRect(
            x: center.x - baseStickerSize / 2,
            y: center.y - baseStickerSize / 2,
            width: baseStickerSize,
            height: baseStickerSize
        )
        imageView.transform = CGAffineTransform(scaleX: stickerDTO.scale, y: stickerDTO.scale)
            .rotated(by: stickerDTO.rotation)

        photoViews.append(imageView)
    }

    private func prepareEditResult() -> (displayImage: UIImage, metadata: ImageSourceData) {
        let stickerDTOs = convertStickersToDTO()
        let filteredBase = photoImageView.image ?? UIImage()
        let hasDrawing = !canvasView.drawing.strokes.isEmpty

        let displayImage: UIImage
        if !stickerDTOs.isEmpty || hasDrawing {
            displayImage = generateFinalImage()
        } else {
            displayImage = filteredBase
        }

        let metadata = ImageSourceData(
            image: filteredBase,
            originalData: initialOriginalData,
            editorViewSize: photoImageView.bounds.size,
            format: initialImageFormat,
            stickers: stickerDTOs,
            filterIndex: currentFilterIndex,
            uncroppedImage: cachedUncroppedOriginalImage,
            cropRect: lastCropRect,
            drawingData: hasDrawing ? canvasView.drawing.dataRepresentation() : nil
        )

        return (displayImage, metadata)
    }

    private func convertStickersToDTO() -> [StickerDTO] {
        guard let image = photoImageView.image else { return [] }

        let displayRect = ImageCoordinateSpace.displayRect(
            imageSize: image.size,
            in: photoImageView.bounds.size
        )
        guard displayRect.width > 0, displayRect.height > 0 else { return [] }

        var allStickers: [StickerDTO] = []
        var currentZIndex = 0

        for stickerView in stickerViews {
            allStickers.append(convertStickerViewToDTO(stickerView, imageSize: image.size, displayRect: displayRect, zIndex: currentZIndex))
            currentZIndex += 1
        }

        for photoView in photoViews {
            allStickers.append(convertPhotoViewToDTO(photoView, imageSize: image.size, displayRect: displayRect, zIndex: currentZIndex))
            currentZIndex += 1
        }

        return allStickers
    }

    private func convertStickerViewToDTO(_ stickerView: DraggableStickerView, imageSize: CGSize, displayRect: CGRect, zIndex: Int) -> StickerDTO {
        let imagePixels = ImageCoordinateSpace.toImagePixels(
            displayCenter: stickerView.center,
            imageSize: imageSize,
            displayRect: displayRect
        )

        return StickerDTO(
            x: imagePixels.x,
            y: imagePixels.y,
            scale: Double(stickerView.transform.extractedScale),
            rotation: Double(stickerView.transform.extractedRotation),
            zIndex: zIndex,
            sourceType: .kilpy,
            resourceUrl: stickerView.stickerURL?.absoluteString,
            localFilePath: nil,
            photoAssetId: nil,
            isAnimated: stickerView.stickerURL != nil
        )
    }

    private func convertPhotoViewToDTO(_ photoView: DraggableImageView, imageSize: CGSize, displayRect: CGRect, zIndex: Int) -> StickerDTO {
        let imagePixels = ImageCoordinateSpace.toImagePixels(
            displayCenter: photoView.center,
            imageSize: imageSize,
            displayRect: displayRect
        )

        var localFilePath: String?
        if let photoImage = photoView.image,
           let imageData = photoImage.jpegData(compressionQuality: 0.9) {
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileName = UUID().uuidString + ".jpg"
            let fileURL = documentsPath.appendingPathComponent("PhotoStickers").appendingPathComponent(fileName)

            try? FileManager.default.createDirectory(at: documentsPath.appendingPathComponent("PhotoStickers"), withIntermediateDirectories: true)
            try? imageData.write(to: fileURL)
            localFilePath = fileURL.path
        }

        return StickerDTO(
            x: imagePixels.x,
            y: imagePixels.y,
            scale: Double(photoView.transform.extractedScale),
            rotation: Double(photoView.transform.extractedRotation),
            zIndex: zIndex,
            sourceType: .photo,
            resourceUrl: nil,
            localFilePath: localFilePath,
            photoAssetId: nil,
            isAnimated: false
        )
    }

}

extension MediaEditorViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == filterCollectionView {
            return MediaEditorFilterHandler.filters.count
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

            let filterItem = MediaEditorFilterHandler.filters[indexPath.item]
            let filter = filterItem.filterName != nil ? CIFilter(name: filterItem.filterName!) : nil
            cell.configure(with: filterItem.name, image: cachedOriginalImageForFilter, filter: filter, context: filterHandler.context)
            return cell
        }
        return UICollectionViewCell()
    }
}

extension MediaEditorViewController: PKCanvasViewDelegate {
    func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
        updateUndoRedoButtons()
        drawingChangedRelay.accept(())
    }
}

extension MediaEditorViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

extension MediaEditorViewController: UIColorPickerViewControllerDelegate {
    func colorPickerViewController(_ viewController: UIColorPickerViewController, didSelect color: UIColor, continuously: Bool) {
        guard !continuously else { return }
        drawingToolStrip.updateColor(color)
    }
}
