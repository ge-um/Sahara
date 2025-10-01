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

enum EditMode {
    case sticker
    case drawing
    case filter
    case text
    case photo
}

final class PhotoEditorViewController: UIViewController {
    private let scrollView = UIScrollView()
    private let contentView = UIView()

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
        button.tag = 0
        return button
    }()

    private lazy var drawingModeButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "그리기"
        config.baseBackgroundColor = .systemGray4
        config.baseForegroundColor = .label
        config.cornerStyle = .medium
        let button = UIButton(configuration: config)
        button.tag = 1
        return button
    }()

    private lazy var filterModeButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "필터"
        config.baseBackgroundColor = .systemGray4
        config.baseForegroundColor = .label
        config.cornerStyle = .medium
        let button = UIButton(configuration: config)
        button.tag = 2
        return button
    }()

    private lazy var textModeButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "텍스트"
        config.baseBackgroundColor = .systemGray4
        config.baseForegroundColor = .label
        config.cornerStyle = .medium
        let button = UIButton(configuration: config)
        button.tag = 3
        return button
    }()

    private lazy var photoModeButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "사진"
        config.baseBackgroundColor = .systemGray4
        config.baseForegroundColor = .label
        config.cornerStyle = .medium
        let button = UIButton(configuration: config)
        button.tag = 4
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
        collectionView.delegate = self
        return collectionView
    }()

    private var filteredImage: UIImage?
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

    private lazy var textColorCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 50, height: 50)
        layout.minimumLineSpacing = 10

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.register(TextColorCell.self, forCellWithReuseIdentifier: TextColorCell.identifier)
        collectionView.dataSource = self
        collectionView.delegate = self
        return collectionView
    }()

    private let textToolbar: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray6
        view.layer.cornerRadius = 12
        view.isHidden = true
        return view
    }()

    private let textColorLabel: UILabel = {
        let label = UILabel()
        label.text = "색상"
        label.font = .systemFont(ofSize: 14, weight: .semibold)
        label.textColor = .secondaryLabel
        return label
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
    private var textViews: [DraggableTextView] = []
    private var photoViews: [DraggableImageView] = []
    private var currentMode: EditMode = .sticker
    private let toolPicker = PKToolPicker()
    private var originalImage: UIImage?
    private let context = CIContext()
    private var currentTextColor: UIColor = .black
    private var currentTextFont: UIFont = .systemFont(ofSize: 24, weight: .bold)
    private let textColors: [UIColor] = [.black, .white, .red, .blue, .green, .yellow, .purple, .orange]
    private let textFonts: [UIFont] = [
        .systemFont(ofSize: 24, weight: .bold),
        .systemFont(ofSize: 24, weight: .regular),
        .italicSystemFont(ofSize: 24),
        .monospacedSystemFont(ofSize: 24, weight: .bold)
    ]

    // MARK: - Init
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
        setupGestures()
        bind()
        updateEditMode()
        updateModeButtons()
    }

    private func setupGestures() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleBackgroundTap))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }

    @objc private func handleBackgroundTap() {
        view.endEditing(true)
    }

    private func setupPencilKit() {
        canvasView.tool = PKInkingTool(.pen, color: .black, width: 5)
        toolPicker.setVisible(false, forFirstResponder: canvasView)
        toolPicker.addObserver(canvasView)
        canvasView.becomeFirstResponder()
    }

    private func bind() {
        stickerModeButton.rx.tap
            .bind(with: self) { owner, _ in
                owner.currentMode = .sticker
                owner.updateEditMode()
                owner.updateModeButtons()
            }
            .disposed(by: disposeBag)

        drawingModeButton.rx.tap
            .bind(with: self) { owner, _ in
                owner.currentMode = .drawing
                owner.updateEditMode()
                owner.updateModeButtons()
            }
            .disposed(by: disposeBag)

        filterModeButton.rx.tap
            .bind(with: self) { owner, _ in
                owner.currentMode = .filter
                owner.updateEditMode()
                owner.updateModeButtons()
            }
            .disposed(by: disposeBag)

        textModeButton.rx.tap
            .bind(with: self) { owner, _ in
                owner.currentMode = .text
                owner.updateEditMode()
                owner.updateModeButtons()
            }
            .disposed(by: disposeBag)

        photoModeButton.rx.tap
            .bind(with: self) { owner, _ in
                owner.presentPhotoPicker()
            }
            .disposed(by: disposeBag)

        let textTapGesture = UITapGestureRecognizer()
        photoImageView.addGestureRecognizer(textTapGesture)

        textTapGesture.rx.event
            .filter { [weak self] _ in self?.currentMode == .text }
            .bind(with: self) { owner, gesture in
                let location = gesture.location(in: owner.photoImageView)
                owner.addTextToPhoto(at: location)
            }
            .disposed(by: disposeBag)

        let searchQuery = searchBar.rx.text
            .orEmpty
            .debounce(.milliseconds(300), scheduler: MainScheduler.instance)
            .distinctUntilChanged()

        let input = PhotoEditorViewModel.Input(
            viewDidLoad: Observable.just(()),
            searchQuery: searchQuery,
            stickerSelected: stickerCollectionView.rx.modelSelected(Sticker.self).asObservable(),
            doneButtonTapped: doneButton.rx.tap.map { [weak self] in
                guard let self = self else { return nil }
                return self.mergeImageWithDrawing()
            }.compactMap { $0 },
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
            .drive(stickerCollectionView.rx.items(
                cellIdentifier: PhotoStickerCell.identifier,
                cellType: PhotoStickerCell.self
            )) { index, sticker, cell in
                cell.configure(with: sticker)
            }
            .disposed(by: disposeBag)

        output.selectedSticker
            .drive(with: self) { owner, sticker in
                owner.addStickerToPhoto(sticker)
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
            let convertedPoint = self.view.convert(view.center, from: view.superview)
            let trashCenter = CGPoint(x: self.trashIconView.frame.midX, y: self.trashIconView.frame.midY)
            let distance = hypot(convertedPoint.x - trashCenter.x, convertedPoint.y - trashCenter.y)

            if distance < 150 {
                if self.trashIconView.isHidden {
                    self.trashIconView.isHidden = false
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

        stickerView.onDragEnded = { [weak self] view in
            guard let self = self else { return }
            self.hideTrashIcon()

            let convertedPoint = self.view.convert(view.center, from: view.superview)
            let trashFrame = self.trashIconView.frame.insetBy(dx: -20, dy: -20)

            if trashFrame.contains(convertedPoint) {
                UIView.animate(withDuration: 0.3, animations: {
                    view.alpha = 0
                    view.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
                }) { _ in
                    view.removeFromSuperview()
                    if let index = self.stickerViews.firstIndex(of: view) {
                        self.stickerViews.remove(at: index)
                    }
                }
            }
        }

        photoImageView.addSubview(stickerView)
        stickerViews.append(stickerView)
    }

    private func showTrashIcon() {
        trashIconView.isHidden = false
        UIView.animate(withDuration: 0.2) {
            self.trashIconView.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        }
    }

    private func hideTrashIcon() {
        UIView.animate(withDuration: 0.2) {
            self.trashIconView.transform = .identity
        } completion: { _ in
            self.trashIconView.isHidden = true
        }
    }

    private func updateEditMode() {
        searchBar.isHidden = true
        stickerCollectionView.isHidden = true
        filterCollectionView.isHidden = true
        textToolbar.isHidden = true
        canvasView.isUserInteractionEnabled = false
        toolPicker.setVisible(false, forFirstResponder: canvasView)

        photoImageView.isUserInteractionEnabled = true

        switch currentMode {
        case .sticker:
            searchBar.isHidden = false
            stickerCollectionView.isHidden = false
        case .drawing:
            canvasView.isUserInteractionEnabled = true
            toolPicker.setVisible(true, forFirstResponder: canvasView)
        case .filter:
            filterCollectionView.isHidden = false
        case .text:
            textToolbar.isHidden = false
        case .photo:
            break
        }
    }

    private func updateModeButtons() {
        let buttons = [stickerModeButton, drawingModeButton, filterModeButton, textModeButton, photoModeButton]
        let modes: [EditMode] = [.sticker, .drawing, .filter, .text, .photo]

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
            filteredImage = originalImage
            return
        }

        guard let ciImage = CIImage(image: originalImage),
              let filter = filters[index].filter else { return }

        filter.setValue(ciImage, forKey: kCIInputImageKey)

        guard let outputImage = filter.outputImage,
              let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else { return }

        let filtered = UIImage(cgImage: cgImage, scale: originalImage.scale, orientation: originalImage.imageOrientation)
        photoImageView.image = filtered
        filteredImage = filtered
    }

    private func addTextToPhoto(at location: CGPoint) {
        let textView = DraggableTextView(frame: .zero)
        textView.configure(text: "텍스트", color: currentTextColor, font: currentTextFont)
        textView.frame = CGRect(x: location.x - 75,
                               y: location.y - 25,
                               width: 150,
                               height: 50)

        textView.onDragChanged = { [weak self] view in
            self?.handleDragChanged(view: view)
        }

        textView.onDragEnded = { [weak self] view in
            self?.handleDragEnded(view: view, in: &self!.textViews)
        }

        textView.onDoubleTap = { [weak self] view in
            self?.editTextView(view)
        }

        photoImageView.addSubview(textView)
        textViews.append(textView)
    }

    private func editTextView(_ textView: DraggableTextView) {
        let alert = UIAlertController(title: "텍스트 편집", message: nil, preferredStyle: .alert)
        alert.addTextField { textField in
            textField.text = textView.text
            textField.placeholder = "텍스트를 입력하세요"
        }

        let saveAction = UIAlertAction(title: "확인", style: .default) { _ in
            if let text = alert.textFields?.first?.text, !text.isEmpty {
                textView.updateText(text)
            }
        }

        let cancelAction = UIAlertAction(title: "취소", style: .cancel)

        alert.addAction(saveAction)
        alert.addAction(cancelAction)

        present(alert, animated: true)
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
            // Remove from array immediately, before animation
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

    private func mergeImageWithDrawing() -> UIView {
        let renderer = UIGraphicsImageRenderer(bounds: photoImageView.bounds)
        let mergedImage = renderer.image { context in
            photoImageView.layer.render(in: context.cgContext)
            canvasView.drawing.image(from: canvasView.bounds, scale: UIScreen.main.scale).draw(in: canvasView.bounds)
        }

        let imageView = UIImageView(image: mergedImage)
        imageView.frame = photoImageView.bounds
        return imageView
    }

    // MARK: - Configure UI
    private func configureUI() {
        view.backgroundColor = .white

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(photoImageView)
        contentView.addSubview(canvasView)
        contentView.addSubview(searchBar)
        contentView.addSubview(stickerCollectionView)
        contentView.addSubview(filterCollectionView)
        contentView.addSubview(textToolbar)
        textToolbar.addSubview(textColorLabel)
        textToolbar.addSubview(textColorCollectionView)
        view.addSubview(modeButtonStackView)
        modeButtonStackView.addArrangedSubview(stickerModeButton)
        modeButtonStackView.addArrangedSubview(drawingModeButton)
        modeButtonStackView.addArrangedSubview(filterModeButton)
        modeButtonStackView.addArrangedSubview(textModeButton)
        modeButtonStackView.addArrangedSubview(photoModeButton)
        view.addSubview(trashIconView)
        view.addSubview(doneButton)

        scrollView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.horizontalEdges.equalToSuperview()
            make.bottom.equalTo(modeButtonStackView.snp.top).offset(-10)
        }

        contentView.snp.makeConstraints { make in
            make.edges.equalTo(scrollView)
            make.width.equalTo(scrollView)
        }

        photoImageView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.horizontalEdges.equalToSuperview().inset(20)
            let availableHeight = UIScreen.main.bounds.height - 400
            make.height.equalTo(min(max(availableHeight * 0.5, 200), 350))
        }

        canvasView.snp.makeConstraints { make in
            make.edges.equalTo(photoImageView)
        }

        searchBar.snp.makeConstraints { make in
            make.top.equalTo(photoImageView.snp.bottom).offset(16)
            make.horizontalEdges.equalToSuperview().inset(20)
            make.height.equalTo(44)
        }

        stickerCollectionView.snp.makeConstraints { make in
            make.top.equalTo(searchBar.snp.bottom).offset(12)
            make.horizontalEdges.equalToSuperview().inset(20)
            make.height.equalTo(100)
            make.bottom.equalToSuperview().offset(-20)
        }

        filterCollectionView.snp.makeConstraints { make in
            make.top.equalTo(photoImageView.snp.bottom).offset(20)
            make.horizontalEdges.equalToSuperview().inset(20)
            make.height.equalTo(120)
            make.bottom.equalToSuperview().offset(-20)
        }

        textToolbar.snp.makeConstraints { make in
            make.top.equalTo(photoImageView.snp.bottom).offset(20)
            make.horizontalEdges.equalToSuperview().inset(20)
            make.height.equalTo(100)
            make.bottom.equalToSuperview().offset(-20)
        }

        textColorLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(12)
        }

        textColorCollectionView.snp.makeConstraints { make in
            make.top.equalTo(textColorLabel.snp.bottom).offset(8)
            make.horizontalEdges.equalToSuperview().inset(12)
            make.bottom.equalToSuperview().inset(12)
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

extension PhotoEditorViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == filterCollectionView {
            return filters.count
        } else if collectionView == textColorCollectionView {
            return textColors.count
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
        } else if collectionView == textColorCollectionView {
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: TextColorCell.identifier,
                for: indexPath
            ) as? TextColorCell else {
                return UICollectionViewCell()
            }
            cell.configure(with: textColors[indexPath.item])
            return cell
        }
        return UICollectionViewCell()
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == filterCollectionView {
            applyFilter(at: indexPath.item)
        } else if collectionView == textColorCollectionView {
            currentTextColor = textColors[indexPath.item]
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
}

final class FilterCell: UICollectionViewCell {
    static let identifier = "FilterCell"

    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        return imageView
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textAlignment = .center
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureUI() {
        contentView.addSubview(imageView)
        contentView.addSubview(nameLabel)

        imageView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(90)
        }

        nameLabel.snp.makeConstraints { make in
            make.top.equalTo(imageView.snp.bottom).offset(4)
            make.horizontalEdges.equalToSuperview()
            make.bottom.equalToSuperview()
        }
    }

    func configure(with name: String, image: UIImage?, filter: CIFilter?, context: CIContext) {
        nameLabel.text = name

        guard let image = image else { return }

        if filter == nil {
            imageView.image = image
            return
        }

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let ciImage = CIImage(image: image),
                  let filter = filter else { return }

            filter.setValue(ciImage, forKey: kCIInputImageKey)

            guard let outputImage = filter.outputImage,
                  let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else { return }

            let filteredImage = UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)

            DispatchQueue.main.async {
                self?.imageView.image = filteredImage
            }
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        nameLabel.text = nil
    }
}

extension PhotoEditorViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)

        guard let itemProvider = results.first?.itemProvider else { return }

        if itemProvider.canLoadObject(ofClass: UIImage.self) {
            itemProvider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
                DispatchQueue.main.async {
                    guard let image = image as? UIImage else { return }
                    self?.addPhotoToCanvas(image)
                }
            }
        }
    }
}

final class TextColorCell: UICollectionViewCell {
    static let identifier = "TextColorCell"

    private let colorView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 20
        view.layer.borderWidth = 2
        view.layer.borderColor = UIColor.systemGray4.cgColor
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(colorView)
        colorView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(40)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with color: UIColor) {
        colorView.backgroundColor = color
        if color == .white {
            colorView.layer.borderColor = UIColor.systemGray3.cgColor
        } else {
            colorView.layer.borderColor = UIColor.clear.cgColor
        }
    }
}

final class DraggableTextView: UIView {
    private let label = UILabel()
    var onDragChanged: ((UIView) -> Void)?
    var onDragEnded: ((UIView) -> Void)?
    var onDoubleTap: ((DraggableTextView) -> Void)?

    var text: String? {
        return label.text
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(label)
        label.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(4)
        }
        label.textAlignment = .center
        label.numberOfLines = 0

        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        addGestureRecognizer(panGesture)

        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch))
        addGestureRecognizer(pinchGesture)

        let rotationGesture = UIRotationGestureRecognizer(target: self, action: #selector(handleRotation))
        addGestureRecognizer(rotationGesture)

        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap))
        doubleTapGesture.numberOfTapsRequired = 2
        addGestureRecognizer(doubleTapGesture)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(text: String, color: UIColor, font: UIFont) {
        label.text = text
        label.textColor = color
        label.font = font
        sizeToFit()
    }

    func updateText(_ text: String) {
        label.text = text
        sizeToFit()
    }

    override func sizeToFit() {
        label.sizeToFit()
        frame.size = CGSize(width: label.frame.width + 8, height: label.frame.height + 8)
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: superview)

        switch gesture.state {
        case .changed:
            center = CGPoint(x: center.x + translation.x, y: center.y + translation.y)
            gesture.setTranslation(.zero, in: superview)
            onDragChanged?(self)
        case .ended:
            onDragEnded?(self)
        default:
            break
        }
    }

    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        if gesture.state == .began || gesture.state == .changed {
            transform = transform.scaledBy(x: gesture.scale, y: gesture.scale)
            gesture.scale = 1.0
        }
    }

    @objc private func handleRotation(_ gesture: UIRotationGestureRecognizer) {
        if gesture.state == .began || gesture.state == .changed {
            transform = transform.rotated(by: gesture.rotation)
            gesture.rotation = 0
        }
    }

    @objc private func handleDoubleTap() {
        onDoubleTap?(self)
    }
}

final class DraggableImageView: UIImageView {
    var onDragChanged: ((UIView) -> Void)?
    var onDragEnded: ((UIView) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentMode = .scaleAspectFit
        isUserInteractionEnabled = true
        layer.cornerRadius = 8
        clipsToBounds = true

        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        addGestureRecognizer(panGesture)

        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch))
        addGestureRecognizer(pinchGesture)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with image: UIImage) {
        self.image = image
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: superview)

        switch gesture.state {
        case .changed:
            center = CGPoint(x: center.x + translation.x, y: center.y + translation.y)
            gesture.setTranslation(.zero, in: superview)
            onDragChanged?(self)
        case .ended:
            onDragEnded?(self)
        default:
            break
        }
    }

    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        if gesture.state == .began || gesture.state == .changed {
            transform = transform.scaledBy(x: gesture.scale, y: gesture.scale)
            gesture.scale = 1.0
        }
    }
}
