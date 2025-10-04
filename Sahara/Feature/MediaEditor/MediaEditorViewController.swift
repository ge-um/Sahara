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
        imageView.isUserInteractionEnabled = false
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

    private let stickerContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = true
        return view
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
        stackView.spacing = 52
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

    private lazy var photoModeButton: UIButton = {
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

    private let cropOverlayView: CropOverlayView = {
        let view = CropOverlayView()
        view.isHidden = true
        view.backgroundColor = .clear
        return view
    }()

    private let cropApplyButton: UIButton = {
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

    private let cropCancelButton: UIButton = {
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
        imageView.image = UIImage(named: "trash")?.withRenderingMode(.alwaysTemplate)
        imageView.tintColor = .white
        imageView.contentMode = .scaleAspectFit
        imageView.isHidden = true
        return imageView
    }()

    private let cropDimOverlay: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        view.isHidden = true
        view.isUserInteractionEnabled = false
        return view
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
    private var lastContainerSize: CGSize = .zero
    private var currentMode = BehaviorRelay<EditMode?>(value: nil)
    private let toolPicker = PKToolPicker()
    private var originalImage: UIImage?
    private var croppedImage: UIImage?
    private var uncropedOriginalImage: UIImage?
    private var lastCropRect: CGRect?
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
        cropApplyButton.applyGradient(.buttonPink)
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

        toolPicker.setVisible(false, forFirstResponder: canvasView)
        toolPicker.addObserver(canvasView)
        canvasView.becomeFirstResponder()

        if let window = view.window {
            toolPicker.frameObscured(in: window)
        }
    }

    private func bind() {
        stickerModeButton.rx.tap
            .bind(with: self) { owner, _ in
                if owner.currentMode.value == .sticker {
                    owner.currentMode.accept(nil)
                } else {
                    owner.currentMode.accept(.sticker)
                    owner.presentStickerModal()
                }
            }
            .disposed(by: disposeBag)

        drawingModeButton.rx.tap
            .bind(with: self) { owner, _ in
                if owner.currentMode.value == .drawing {
                    owner.currentMode.accept(nil)
                } else {
                    owner.currentMode.accept(.drawing)
                }
            }
            .disposed(by: disposeBag)

        filterModeButton.rx.tap
            .bind(with: self) { owner, _ in
                if owner.currentMode.value == .filter {
                    owner.currentMode.accept(nil)
                } else {
                    owner.currentMode.accept(.filter)
                }
            }
            .disposed(by: disposeBag)

        photoModeButton.rx.tap
            .bind(with: self) { owner, _ in
                if owner.currentMode.value == .photo {
                    owner.currentMode.accept(nil)
                } else {
                    owner.currentMode.accept(.photo)
                }
            }
            .disposed(by: disposeBag)

        cropModeButton.rx.tap
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
            loadMoreTrigger: .empty(),
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
                owner.uncropedOriginalImage = image
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

        stickerView.onDragChanged = { [weak self] view in
            self?.dragHandler.handleDragChanged(view: view)
        }

        stickerView.onDragEnded = { [weak self] view in
            guard let self = self else { return }
            _ = self.dragHandler.handleDragEnded(view: view, in: &self.stickerViews)
        }

        stickerContainerView.addSubview(stickerView)

        let centerX = stickerContainerView.bounds.midX
        let centerY = stickerContainerView.bounds.midY
        stickerView.frame = CGRect(x: centerX - 50, y: centerY - 50, width: 100, height: 100)

        stickerViews.append(stickerView)
    }

    private func addPhotoToCanvas(_ image: UIImage) {
        let imageView = DraggableImageView(frame: .zero)
        imageView.configure(with: image)

        imageView.onDragChanged = { [weak self] view in
            self?.dragHandler.handleDragChanged(view: view)
        }

        imageView.onDragEnded = { [weak self] view in
            guard let self = self else { return }
            _ = self.dragHandler.handleDragEnded(view: view, in: &self.photoViews)
        }

        stickerContainerView.addSubview(imageView)

        let centerX = stickerContainerView.bounds.midX
        let centerY = stickerContainerView.bounds.midY
        imageView.frame = CGRect(x: centerX - 50, y: centerY - 50, width: 100, height: 100)

        photoViews.append(imageView)
    }

    private func adjustStickerPositions() {
        view.layoutIfNeeded()

        guard lastContainerSize.width > 0, lastContainerSize.height > 0,
              stickerContainerView.bounds.width > 0, stickerContainerView.bounds.height > 0 else {
            lastContainerSize = stickerContainerView.bounds.size
            return
        }

        let scaleX = stickerContainerView.bounds.width / lastContainerSize.width
        let scaleY = stickerContainerView.bounds.height / lastContainerSize.height

        guard scaleX != 1.0 || scaleY != 1.0 else {
            return
        }

        adjustViewsWithScale(scaleX: scaleX, scaleY: scaleY)
        adjustDrawingWithScale(scaleX: scaleX, scaleY: scaleY)

        lastContainerSize = stickerContainerView.bounds.size
    }

    private func adjustViewsWithScale(scaleX: CGFloat, scaleY: CGFloat) {
        UIView.animate(withDuration: 0.3) {
            self.stickerViews.forEach { view in
                view.center = CGPoint(
                    x: view.center.x * scaleX,
                    y: view.center.y * scaleY
                )
            }

            self.photoViews.forEach { view in
                view.center = CGPoint(
                    x: view.center.x * scaleX,
                    y: view.center.y * scaleY
                )
            }
        }
    }

    private func adjustDrawingWithScale(scaleX: CGFloat, scaleY: CGFloat) {
        guard !canvasView.drawing.strokes.isEmpty else { return }

        let scaleTransform = CGAffineTransform(scaleX: scaleX, y: scaleY)
        canvasView.drawing = canvasView.drawing.transformed(using: scaleTransform)
    }


    private func updateEditMode(mode: EditMode?) {
        filterCollectionView.isHidden = true
        canvasView.isUserInteractionEnabled = false
        toolPicker.setVisible(false, forFirstResponder: canvasView)
        photoImageView.isUserInteractionEnabled = false
        stickerContainerView.isUserInteractionEnabled = true
        cropOverlayView.isHidden = true
        cropApplyButton.isHidden = true
        cropCancelButton.isHidden = true
        cropDimOverlay.isHidden = true
        toolBarContainer.isHidden = false
        doneButton.isHidden = false
        leftStarImageView.isHidden = false
        rightStarImageView.isHidden = false
        cancelButton.isEnabled = true

        photoImageView.snp.remakeConstraints { make in
            make.top.equalTo(customNavigationBar.snp.bottom).offset(40)
            make.horizontalEdges.equalToSuperview().inset(40)
            make.bottom.equalTo(toolBarContainer.snp.top).offset(-48)
        }

        stickerContainerView.snp.remakeConstraints { make in
            make.edges.equalTo(photoImageView)
        }

        canvasView.snp.remakeConstraints { make in
            make.edges.equalTo(photoImageView)
        }

        toolBarContainer.snp.remakeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(88)
        }

        UIView.animate(withDuration: 0.3, animations: {
            self.view.layoutIfNeeded()
        }, completion: { _ in
            self.adjustStickerPositions()
        })

        guard let mode = mode else {
            doneButton.isHidden = false
            doneButton.isEnabled = true
            doneButton.alpha = 1.0
            return
        }

        switch mode {
        case .sticker:
            break
        case .drawing:
            canvasView.isUserInteractionEnabled = true

            toolBarContainer.snp.remakeConstraints { make in
                make.leading.trailing.equalToSuperview()
                make.height.equalTo(88)
                make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-75)
            }

            UIView.animate(withDuration: 0.3, animations: {
                self.view.layoutIfNeeded()
            }, completion: { _ in
                self.adjustStickerPositions()
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
                self.adjustStickerPositions()
                self.filterCollectionView.reloadData()
                self.filterCollectionView.layoutIfNeeded()
            })
        case .photo:
            presentPhotoSelectionModal()
        case .crop:
            leftStarImageView.isHidden = true
            rightStarImageView.isHidden = true
            cropDimOverlay.isHidden = false
            cancelButton.isEnabled = false
            doneButton.alpha = 0.5
            doneButton.isEnabled = false

            cropApplyButton.snp.remakeConstraints { make in
                make.trailing.equalToSuperview().inset(20)
                make.bottom.equalTo(toolBarContainer.snp.top).offset(-28)
                make.width.greaterThanOrEqualTo(80)
                make.height.equalTo(44)
            }

            cropCancelButton.snp.remakeConstraints { make in
                make.leading.equalToSuperview().inset(20)
                make.bottom.equalTo(toolBarContainer.snp.top).offset(-28)
                make.width.greaterThanOrEqualTo(80)
                make.height.equalTo(44)
            }

            photoImageView.snp.remakeConstraints { make in
                make.top.equalTo(customNavigationBar.snp.bottom).offset(20)
                make.horizontalEdges.equalToSuperview().inset(20)
                make.bottom.equalTo(cropApplyButton.snp.top).offset(-20)
            }

            cropOverlayView.isHidden = false
            cropApplyButton.isHidden = false
            cropCancelButton.isHidden = false
            doneButton.isHidden = false

            guard let uncropped = uncropedOriginalImage else { return }
            photoImageView.image = uncropped

            UIView.animate(withDuration: 0.3, animations: {
                self.view.layoutIfNeeded()
            }, completion: { _ in
                self.adjustStickerPositions()
                self.setupCropOverlay()
            })
        }
    }

    private func updateModeButtons(currentMode: EditMode?) {
        let buttons = [stickerModeButton, drawingModeButton, filterModeButton, photoModeButton, cropModeButton]
        let modes: [EditMode?] = [.sticker, .drawing, .filter, .photo, .crop]

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

    private func presentPhotoSelectionModal() {
        let mediaSelectionVC = MediaSelectionViewController()
        mediaSelectionVC.onMediaSelected = { [weak self] image, _, _ in
            self?.addPhotoToCanvas(image)
            self?.currentMode.accept(nil)
        }
        let navController = UINavigationController(rootViewController: mediaSelectionVC)
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
            stickerContainerView.layer.render(in: context.cgContext)

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
        guard let uncropped = uncropedOriginalImage else { return }

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            let imageRect = MediaEditorCropHandler.calculateDisplayedImageRect(
                imageSize: uncropped.size,
                in: self.photoImageView.bounds.size
            )

            let overlayFrame = self.photoImageView.convert(self.photoImageView.bounds, to: self.view)
            self.cropOverlayView.frame = overlayFrame

            let imageRectInOverlay = CGRect(
                x: imageRect.origin.x,
                y: imageRect.origin.y,
                width: imageRect.width,
                height: imageRect.height
            )

            self.cropOverlayView.imageRect = imageRectInOverlay

            if let lastCrop = self.lastCropRect {
                let scale = imageRect.width / uncropped.size.width

                let scaledCropRect = CGRect(
                    x: imageRect.origin.x + (lastCrop.origin.x * scale),
                    y: imageRect.origin.y + (lastCrop.origin.y * scale),
                    width: lastCrop.width * scale,
                    height: lastCrop.height * scale
                )

                self.cropOverlayView.setCropRect(scaledCropRect)
            } else {
                self.cropOverlayView.setCropRect(imageRectInOverlay)
            }
        }
    }

    private func applyCrop() {
        guard let uncropped = uncropedOriginalImage else { return }

        let cropRectInOverlay = cropOverlayView.cropRect
        let imageRectInOverlay = cropOverlayView.imageRect

        let relativeX = cropRectInOverlay.origin.x - imageRectInOverlay.origin.x
        let relativeY = cropRectInOverlay.origin.y - imageRectInOverlay.origin.y
        let relativeWidth = cropRectInOverlay.width
        let relativeHeight = cropRectInOverlay.height

        let scale = uncropped.size.width / imageRectInOverlay.width

        let cropRectInImage = CGRect(
            x: relativeX * scale,
            y: relativeY * scale,
            width: relativeWidth * scale,
            height: relativeHeight * scale
        )

        // orientation을 고려하여 이미지를 정규화
        guard let _ = uncropped.cgImage else {
            currentMode.accept(nil)
            return
        }

        // orientation이 있으면 이미지를 다시 그려서 정규화
        let normalizedImage: UIImage
        if uncropped.imageOrientation != .up {
            UIGraphicsBeginImageContextWithOptions(uncropped.size, false, uncropped.scale)
            uncropped.draw(in: CGRect(origin: .zero, size: uncropped.size))
            normalizedImage = UIGraphicsGetImageFromCurrentImageContext() ?? uncropped
            UIGraphicsEndImageContext()
        } else {
            normalizedImage = uncropped
        }

        guard let normalizedCGImage = normalizedImage.cgImage,
              let croppedCGImage = normalizedCGImage.cropping(to: cropRectInImage) else {
            currentMode.accept(nil)
            return
        }

        let croppedImage = UIImage(
            cgImage: croppedCGImage,
            scale: normalizedImage.scale,
            orientation: .up
        )

        lastCropRect = cropRectInImage

        photoImageView.image = croppedImage
        originalImage = croppedImage

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
            (photoModeButton, "image", "media_editor.photo"),
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
        view.addSubview(stickerContainerView)
        view.addSubview(canvasView)
        view.addSubview(toolBarContainer)
        view.addSubview(filterCollectionView)
        view.addSubview(trashIconView)
        view.addSubview(leftStarImageView)
        view.addSubview(rightStarImageView)
        view.addSubview(cropDimOverlay)
        view.addSubview(cropOverlayView)
        view.addSubview(cropApplyButton)
        view.addSubview(cropCancelButton)

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
            make.height.equalTo(88)
        }

        toolBarScrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        modeButtonStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 16, left: 20, bottom: 8, right: 20))
            make.height.equalTo(54)
        }

        photoImageView.snp.makeConstraints { make in
            make.top.equalTo(customNavigationBar.snp.bottom).offset(40)
            make.horizontalEdges.equalToSuperview().inset(40)
            make.bottom.equalTo(toolBarContainer.snp.top).offset(-48)
        }


        stickerContainerView.snp.makeConstraints { make in
            make.edges.equalTo(photoImageView)
        }

        canvasView.snp.makeConstraints { make in
            make.edges.equalTo(photoImageView)
        }

        filterCollectionView.snp.makeConstraints { make in
            make.bottom.equalTo(toolBarContainer.snp.top).offset(-28)
            make.horizontalEdges.equalToSuperview().inset(40)
            make.height.equalTo(144)
        }

        trashIconView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(toolBarContainer.snp.top).offset(-28)
            make.width.height.equalTo(40)
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

        cropDimOverlay.snp.makeConstraints { make in
            make.edges.equalToSuperview()
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
