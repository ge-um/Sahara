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

    lazy var filterCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 100, height: 120)
        layout.minimumLineSpacing = 10
        layout.sectionInset = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = ColorSystem.purpleGray20
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.register(FilterCell.self, forCellWithReuseIdentifier: FilterCell.identifier)
        collectionView.dataSource = self
        collectionView.layer.cornerRadius = 12
        collectionView.clipsToBounds = true
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
    private let disposeBag = DisposeBag()
    var onEditingComplete: ((UIImage) -> Void)?

    private var stickerViews: [DraggableStickerView] = []
    private var photoViews: [DraggableImageView] = []
    private var lastContainerSize: CGSize = .zero
    let currentMode = BehaviorRelay<EditMode?>(value: nil)
    let toolPicker = PKToolPicker()
    var originalImage: UIImage?
    private var croppedImage: UIImage?
    var uncropedOriginalImage: UIImage?
    var lastCropRect: CGRect?
    private let filterHandler = MediaEditorFilterHandler()
    private let filterSelectedRelay = PublishRelay<(Int, UIImage?)>()
    let photoSelectedRelay = PublishRelay<UIImage>()
    private let viewWillAppearRelay = PublishRelay<Void>()
    private var usedTools: Set<String> = []

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
        doneButton.applyGradient(.hotPink)
        cropApplyButton.applyGradient(.hotPink)
        updateStarPositions()
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
            .do(onNext: { [weak self] _ in
                guard let self = self, self.currentMode.value != .sticker else { return }
                self.usedTools.insert("sticker")
                AnalyticsManager.shared.logPhotoEditToolUsed(tool: "sticker")
            })
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
            .do(onNext: { [weak self] _ in
                guard let self = self, self.currentMode.value != .drawing else { return }
                self.usedTools.insert("drawing")
                AnalyticsManager.shared.logPhotoEditToolUsed(tool: "drawing")
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
                AnalyticsManager.shared.logPhotoEditToolUsed(tool: "filter")
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
                AnalyticsManager.shared.logPhotoEditToolUsed(tool: "photo")
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
                AnalyticsManager.shared.logPhotoEditToolUsed(tool: "crop")
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
            cropApplied: Observable.just((UIImage(), CGRect.zero, CGRect.zero)),
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
            .do(onNext: { [weak self] _ in
                guard let self = self else { return }
                AnalyticsManager.shared.logPhotoEditComplete(toolsUsedCount: self.usedTools.count)
            })
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

    func addStickerToPhoto(_ sticker: KlipySticker) {
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

    func addPhotoToCanvas(_ image: UIImage) {
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

    func adjustStickerPositions() {
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
            cell.configure(with: filterItem.name, image: originalImage, filter: filter, context: filterHandler.context)
            return cell
        }
        return UICollectionViewCell()
    }
}
