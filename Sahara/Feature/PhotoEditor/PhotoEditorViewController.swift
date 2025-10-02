//
//  PhotoEditorViewController.swift
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

final class PhotoEditorViewController: UIViewController {
    private let photoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = true
        imageView.backgroundColor = .white
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

    private let modeButtonStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 8
        return stackView
    }()

    private lazy var stickerModeButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = NSLocalizedString("photo_editor.sticker", comment: "")
        config.baseBackgroundColor = .systemBlue
        config.baseForegroundColor = .white
        config.cornerStyle = .medium
        let button = UIButton(configuration: config)
        return button
    }()

    private lazy var drawingModeButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = NSLocalizedString("photo_editor.drawing", comment: "")
        config.baseBackgroundColor = .systemGray4
        config.baseForegroundColor = .label
        config.cornerStyle = .medium
        let button = UIButton(configuration: config)
        return button
    }()

    private lazy var filterModeButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = NSLocalizedString("photo_editor.filter", comment: "")
        config.baseBackgroundColor = .systemGray4
        config.baseForegroundColor = .label
        config.cornerStyle = .medium
        let button = UIButton(configuration: config)
        return button
    }()

    private lazy var photoModeButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = NSLocalizedString("photo_editor.photo", comment: "")
        config.baseBackgroundColor = .systemGray4
        config.baseForegroundColor = .label
        config.cornerStyle = .medium
        let button = UIButton(configuration: config)
        return button
    }()

    private lazy var cropModeButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = NSLocalizedString("photo_editor.crop", comment: "")
        config.baseBackgroundColor = .systemGray4
        config.baseForegroundColor = .label
        config.cornerStyle = .medium
        let button = UIButton(configuration: config)
        return button
    }()

    private let cropOverlayView: CropOverlayView = {
        let view = CropOverlayView()
        view.isHidden = true
        return view
    }()

    private let cropApplyButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = NSLocalizedString("photo_editor.apply", comment: "")
        config.baseBackgroundColor = .systemBlue
        config.baseForegroundColor = .white
        config.cornerStyle = .medium
        let button = UIButton(configuration: config)
        button.isHidden = true
        return button
    }()

    private let cropCancelButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.title = NSLocalizedString("photo_editor.cancel", comment: "")
        let button = UIButton(configuration: config)
        button.isHidden = true
        return button
    }()

    private lazy var filterCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 100, height: 120)
        layout.minimumLineSpacing = 10

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .systemGray6
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.register(FilterCell.self, forCellWithReuseIdentifier: FilterCell.identifier)
        collectionView.dataSource = self
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

    private lazy var doneButton = UIBarButtonItem(title: NSLocalizedString("photo_editor.done", comment: ""), style: .done, target: nil, action: nil)
    private lazy var cancelButton = UIBarButtonItem(title: NSLocalizedString("photo_editor.cancel", comment: ""), style: .plain, target: nil, action: nil)

    private let viewModel: PhotoEditorViewModel
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

    private lazy var dragHandler = PhotoEditorDragHandler(
        trashIconView: trashIconView,
        parentView: view
    )

    init(viewModel: PhotoEditorViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        configureNavigation()
        setupPencilKit()
        bind()
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

        photoModeButton.rx.tap
            .bind(with: self) { owner, _ in
                owner.presentPhotoPicker()
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

        let input = PhotoEditorViewModel.Input(
            viewWillAppear: viewWillAppearRelay.asObservable(),
            searchQuery: .empty(),
            stickerSelected: .empty(),
            filterSelected: filterSelectedRelay.asObservable(),
            cropApplied: cropAppliedRelay.asObservable(),
            drawingChanged: Observable.just(()),
            photoSelected: photoSelectedRelay.asObservable(),
            doneButtonTapped: doneButton.rx.tap.map { [weak self] in
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
                    let metadataViewModel = PhotoInfoViewModel(editedImage: editedImage)
                    let metadataVC = PhotoInfoViewController(viewModel: metadataViewModel)
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
        modeButtonStackView.isHidden = false
        doneButton.isHidden = false

        guard let mode = mode else {
            doneButton.isHidden = false
            return
        }

        switch mode {
        case .sticker:
            break
        case .drawing:
            canvasView.isUserInteractionEnabled = true
            toolPicker.setVisible(true, forFirstResponder: canvasView)
        case .filter:
            filterCollectionView.isHidden = false
        case .photo:
            break
        case .crop:
            cropOverlayView.isHidden = false
            cropApplyButton.isHidden = false
            cropCancelButton.isHidden = false
            modeButtonStackView.isHidden = true
            doneButton.isHidden = true
            guard let original = originalImage else { return }
            photoImageView.image = original
            setupCropOverlay()
        }
    }

    private func updateModeButtons(currentMode: EditMode?) {
        let buttons = [stickerModeButton, drawingModeButton, filterModeButton, cropModeButton, photoModeButton]
        let modes: [EditMode?] = [.sticker, .drawing, .filter, .crop, .photo]

        for (button, mode) in zip(buttons, modes) {
            var config = button.configuration
            if mode == currentMode {
                config?.baseBackgroundColor = .systemBlue
                config?.baseForegroundColor = .white
            } else {
                config?.baseBackgroundColor = .systemGray4
                config?.baseForegroundColor = .label
            }
            button.configuration = config
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
        modeButtonStackView.isHidden = true

        let renderer = UIGraphicsImageRenderer(bounds: photoImageView.bounds)
        let image = renderer.image { context in
            photoImageView.layer.render(in: context.cgContext)

            let canvasFrame = canvasView.frame
            let drawingImage = canvasView.drawing.image(from: canvasView.bounds, scale: UIScreen.main.scale)
            drawingImage.draw(in: canvasFrame)
        }

        modeButtonStackView.isHidden = false

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

        let imageRect = PhotoEditorCropHandler.calculateDisplayedImageRect(
            imageSize: currentImage.size,
            in: photoImageView.bounds.size
        )

        cropOverlayView.frame = photoImageView.bounds
        cropOverlayView.setCropRect(imageRect)
    }

    private func applyCrop() {
        guard let currentImage = photoImageView.image else { return }

        let cropRect = cropOverlayView.cropRect
        let displayedImageRect = PhotoEditorCropHandler.calculateDisplayedImageRect(
            imageSize: currentImage.size,
            in: photoImageView.bounds.size
        )

        cropAppliedRelay.accept((currentImage, cropRect, displayedImageRect))
        currentMode.accept(nil)
    }

    private func configureUI() {
        view.backgroundColor = .white

        view.addSubview(photoImageView)
        view.addSubview(canvasView)
        view.addSubview(modeButtonStackView)
        view.addSubview(filterCollectionView)
        view.addSubview(trashIconView)
        view.addSubview(cropOverlayView)
        view.addSubview(cropApplyButton)
        view.addSubview(cropCancelButton)

        modeButtonStackView.addArrangedSubview(stickerModeButton)
        modeButtonStackView.addArrangedSubview(drawingModeButton)
        modeButtonStackView.addArrangedSubview(filterModeButton)
        modeButtonStackView.addArrangedSubview(cropModeButton)
        modeButtonStackView.addArrangedSubview(photoModeButton)

        modeButtonStackView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(20)
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(100)
            make.height.equalTo(40)
        }

        photoImageView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.horizontalEdges.equalToSuperview()
            make.bottom.equalTo(modeButtonStackView.snp.top).offset(-20)
        }

        canvasView.snp.makeConstraints { make in
            make.edges.equalTo(photoImageView)
        }

        filterCollectionView.snp.makeConstraints { make in
            make.bottom.equalTo(modeButtonStackView.snp.top).offset(-16)
            make.horizontalEdges.equalToSuperview().inset(20)
            make.height.equalTo(120)
        }

        trashIconView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(modeButtonStackView.snp.top).offset(-20)
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

    private func configureNavigation() {
        navigationItem.title = NSLocalizedString("photo_editor.title", comment: "")
        navigationItem.leftBarButtonItem = cancelButton
        navigationItem.rightBarButtonItem = doneButton
    }
}

extension PhotoEditorViewController: UICollectionViewDataSource {
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

extension PhotoEditorViewController: PHPickerViewControllerDelegate {
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
