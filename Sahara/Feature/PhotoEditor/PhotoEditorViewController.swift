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
        config.title = "스티커"
        config.baseBackgroundColor = .systemBlue
        config.baseForegroundColor = .white
        config.cornerStyle = .medium
        let button = UIButton(configuration: config)
        return button
    }()

    private lazy var drawingModeButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "그리기"
        config.baseBackgroundColor = .systemGray4
        config.baseForegroundColor = .label
        config.cornerStyle = .medium
        let button = UIButton(configuration: config)
        return button
    }()

    private lazy var filterModeButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "필터"
        config.baseBackgroundColor = .systemGray4
        config.baseForegroundColor = .label
        config.cornerStyle = .medium
        let button = UIButton(configuration: config)
        return button
    }()

    private lazy var photoModeButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "사진"
        config.baseBackgroundColor = .systemGray4
        config.baseForegroundColor = .label
        config.cornerStyle = .medium
        let button = UIButton(configuration: config)
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

    private let filters: [(name: String, filter: CIFilter?)] = [
        ("원본", nil),
        ("흑백", CIFilter(name: "CIPhotoEffectNoir")),
        ("세피아", CIFilter(name: "CISepiaTone")),
        ("빈티지", CIFilter(name: "CIPhotoEffectInstant")),
        ("크롬", CIFilter(name: "CIPhotoEffectChrome")),
        ("페이드", CIFilter(name: "CIPhotoEffectFade")),
        ("모노", CIFilter(name: "CIPhotoEffectMono")),
        ("프로세스", CIFilter(name: "CIPhotoEffectProcess")),
        ("전송", CIFilter(name: "CIPhotoEffectTransfer")),
        ("토널", CIFilter(name: "CIPhotoEffectTonal"))
    ]

    private let searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = "스티커 검색"
        searchBar.searchBarStyle = .minimal
        return searchBar
    }()

    private lazy var stickerCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 80, height: 80)
        layout.minimumLineSpacing = 10
        layout.minimumInteritemSpacing = 10

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .systemGray6
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.register(PhotoStickerCell.self, forCellWithReuseIdentifier: PhotoStickerCell.identifier)
        return collectionView
    }()

    private let trashIconView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "trash.fill")
        imageView.tintColor = .systemRed
        imageView.contentMode = .scaleAspectFit
        imageView.isHidden = true
        return imageView
    }()

    private let doneButton: UIButton = {
        let button = UIButton()
        var config = UIButton.Configuration.filled()
        config.title = "완료"
        config.baseBackgroundColor = .systemBlue
        button.configuration = config
        return button
    }()

    private let cancelButton: UIButton = {
        let button = UIButton()
        var config = UIButton.Configuration.plain()
        config.title = "취소"
        button.configuration = config
        return button
    }()

    private let viewModel: PhotoEditorViewModel
    private let disposeBag = DisposeBag()
    
    private var stickerViews: [DraggableStickerView] = []
    private var photoViews: [DraggableImageView] = []
    private var currentMode = BehaviorRelay<EditMode>(value: .sticker)
    private let toolPicker = PKToolPicker()
    private var originalImage: UIImage?
    private let context = CIContext()
    private let filterSelectedRelay = PublishRelay<Int>()
    private let photoSelectedRelay = PublishRelay<UIImage>()
    private let viewWillAppearRelay = PublishRelay<Void>()

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
        toolPicker.setVisible(false, forFirstResponder: canvasView)
        toolPicker.addObserver(canvasView)
        canvasView.becomeFirstResponder()
    }

    private func bind() {
        let stickerModeTapped = stickerModeButton.rx.tap
            .map { EditMode.sticker }

        let drawingModeTapped = drawingModeButton.rx.tap
            .map { EditMode.drawing }

        let filterModeTapped = filterModeButton.rx.tap
            .map { EditMode.filter }

        Observable.merge(stickerModeTapped, drawingModeTapped, filterModeTapped)
            .bind(to: currentMode)
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

        let searchQuery = searchBar.rx.text
            .orEmpty
            .debounce(.milliseconds(300), scheduler: MainScheduler.instance)
            .distinctUntilChanged()

        let input = PhotoEditorViewModel.Input(
            viewWillAppear: viewWillAppearRelay.asObservable(),
            searchQuery: searchQuery,
            stickerSelected: stickerCollectionView.rx.modelSelected(Sticker.self).asObservable(),
            filterSelected: filterSelectedRelay.asObservable(),
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

        output.stickers
            .asObservable()
            .bind(to: stickerCollectionView.rx.items(
                cellIdentifier: PhotoStickerCell.identifier,
                cellType: PhotoStickerCell.self
            )) { _, sticker, cell in
                cell.configure(with: sticker)
            }
            .disposed(by: disposeBag)

        output.selectedSticker
            .drive(with: self) { owner, sticker in
                owner.addStickerToPhoto(sticker)
            }
            .disposed(by: disposeBag)

        output.selectedFilter
            .drive(with: self) { owner, index in
                owner.applyFilter(at: index)
            }
            .disposed(by: disposeBag)

        output.selectedPhoto
            .drive(with: self) { owner, image in
                owner.addPhotoToCanvas(image)
            }
            .disposed(by: disposeBag)

        output.navigateToMetadata
            .drive(with: self) { owner, editedImage in
                let metadataViewModel = PhotoInfoViewModel(editedImage: editedImage)
                let metadataVC = PhotoInfoViewController(viewModel: metadataViewModel)
                owner.navigationController?.pushViewController(metadataVC, animated: true)
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
            .map { $0.item }
            .bind(to: filterSelectedRelay)
            .disposed(by: disposeBag)
    }

    private func addStickerToPhoto(_ sticker: Sticker) {
        let stickerView = DraggableStickerView()
        stickerView.configure(with: sticker)
        stickerView.frame = CGRect(x: photoImageView.bounds.midX - 50,
                                   y: photoImageView.bounds.midY - 50,
                                   width: 100,
                                   height: 100)

        stickerView.onDragChanged = { [weak self] view in
            guard let self = self else { return }
            self.handleDragChanged(view: view)
        }

        stickerView.onDragEnded = { [weak self] view in
            guard let self = self else { return }
            self.handleDragEnded(view: view, in: &self.stickerViews)
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
            self?.handleDragChanged(view: view)
        }

        imageView.onDragEnded = { [weak self] view in
            self?.handleDragEnded(view: view, in: &self!.photoViews)
        }

        photoImageView.addSubview(imageView)
        photoViews.append(imageView)
    }

    private func handleDragChanged(view: UIView) {
        let convertedPoint = self.view.convert(view.center, from: view.superview)
        let trashCenter = CGPoint(x: trashIconView.frame.midX, y: trashIconView.frame.midY)
        let distance = hypot(convertedPoint.x - trashCenter.x, convertedPoint.y - trashCenter.y)

        if distance < 150 {
            if trashIconView.isHidden {
                trashIconView.isHidden = false
            }
            let scale = max(1.0, 1.5 - (distance / 150))
            UIView.animate(withDuration: 0.1) {
                self.trashIconView.transform = CGAffineTransform(scaleX: scale, y: scale)
            }
        } else {
            UIView.animate(withDuration: 0.1) {
                self.trashIconView.transform = .identity
            }
        }
    }

    private func handleDragEnded<T: UIView>(view: UIView, in array: inout [T]) {
        hideTrashIcon()

        let convertedPoint = self.view.convert(view.center, from: view.superview)
        let trashFrame = trashIconView.frame.insetBy(dx: -20, dy: -20)

        if trashFrame.contains(convertedPoint) {
            if let index = array.firstIndex(where: { $0 === view }) {
                array.remove(at: index)
            }

            UIView.animate(withDuration: 0.3, animations: {
                view.alpha = 0
                view.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
            }) { _ in
                view.removeFromSuperview()
            }
        }
    }

    private func hideTrashIcon() {
        UIView.animate(withDuration: 0.2) {
            self.trashIconView.transform = .identity
        } completion: { _ in
            self.trashIconView.isHidden = true
        }
    }

    private func updateEditMode(mode: EditMode) {
        searchBar.isHidden = true
        stickerCollectionView.isHidden = true
        filterCollectionView.isHidden = true
        canvasView.isUserInteractionEnabled = false
        toolPicker.setVisible(false, forFirstResponder: canvasView)
        photoImageView.isUserInteractionEnabled = true

        switch mode {
        case .sticker:
            searchBar.isHidden = false
            stickerCollectionView.isHidden = false
        case .drawing:
            canvasView.isUserInteractionEnabled = true
            toolPicker.setVisible(true, forFirstResponder: canvasView)
        case .filter:
            filterCollectionView.isHidden = false
        case .photo:
            break
        }
    }

    private func updateModeButtons(currentMode: EditMode) {
        let buttons = [stickerModeButton, drawingModeButton, filterModeButton, photoModeButton]
        let modes: [EditMode] = [.sticker, .drawing, .filter, .photo]

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

    private func applyFilter(at index: Int) {
        guard let originalImage = originalImage else { return }

        if index == 0 {
            photoImageView.image = originalImage
            return
        }

        guard let ciImage = CIImage(image: originalImage),
              let filter = filters[index].filter else { return }

        filter.setValue(ciImage, forKey: kCIInputImageKey)

        guard let outputImage = filter.outputImage,
              let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else { return }

        let filtered = UIImage(cgImage: cgImage, scale: originalImage.scale, orientation: originalImage.imageOrientation)
        photoImageView.image = filtered
    }

    private func generateFinalImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(bounds: photoImageView.bounds)
        return renderer.image { context in
            photoImageView.layer.render(in: context.cgContext)
            canvasView.drawing.image(from: canvasView.bounds, scale: UIScreen.main.scale).draw(in: canvasView.bounds)
        }
    }

    private func presentPhotoPicker() {
        var configuration = PHPickerConfiguration()
        configuration.selectionLimit = 1
        configuration.filter = .images
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
    }

    private func configureUI() {
        view.backgroundColor = .white

        view.addSubview(photoImageView)
        view.addSubview(canvasView)
        view.addSubview(searchBar)
        view.addSubview(stickerCollectionView)
        view.addSubview(filterCollectionView)
        view.addSubview(modeButtonStackView)
        modeButtonStackView.addArrangedSubview(stickerModeButton)
        modeButtonStackView.addArrangedSubview(drawingModeButton)
        modeButtonStackView.addArrangedSubview(filterModeButton)
        modeButtonStackView.addArrangedSubview(photoModeButton)
        view.addSubview(trashIconView)
        view.addSubview(doneButton)

        photoImageView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.horizontalEdges.equalToSuperview()
            make.bottom.equalTo(modeButtonStackView.snp.top).offset(-10)
        }

        canvasView.snp.makeConstraints { make in
            make.edges.equalTo(photoImageView)
        }

        searchBar.snp.makeConstraints { make in
            make.bottom.equalTo(stickerCollectionView.snp.top).offset(-8)
            make.horizontalEdges.equalToSuperview().inset(20)
            make.height.equalTo(44)
        }

        stickerCollectionView.snp.makeConstraints { make in
            make.bottom.equalTo(modeButtonStackView.snp.top).offset(-16)
            make.horizontalEdges.equalToSuperview().inset(20)
            make.height.equalTo(100)
        }

        filterCollectionView.snp.makeConstraints { make in
            make.bottom.equalTo(modeButtonStackView.snp.top).offset(-16)
            make.horizontalEdges.equalToSuperview().inset(20)
            make.height.equalTo(120)
        }

        modeButtonStackView.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview().inset(20)
            make.bottom.equalTo(doneButton.snp.top).offset(-10)
            make.height.equalTo(40)
        }

        trashIconView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(modeButtonStackView.snp.top).offset(-20)
            make.width.height.equalTo(60)
        }

        doneButton.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview().inset(20)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-10)
            make.height.equalTo(50)
        }

    }

    private func configureNavigation() {
        navigationItem.title = "사진 편집"
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: cancelButton)
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
