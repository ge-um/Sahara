//
//  MediaSelectionViewController.swift
//  Sahara
//
//  Created by 금가경 on 9/26/25.
//

import AVFoundation
import Photos
import PhotosUI
import RxCocoa
import RxDataSources
import RxSwift
import SnapKit
import UIKit
import UniformTypeIdentifiers

enum MediaCollectionItem {
    case action(icon: String, title: String, type: ActionType)
    case photo(asset: PHAsset)
}

enum ActionType {
    case camera
    case library
    case filePicker
}

final class MediaSelectionViewController: UIViewController {
    private let viewModel = MediaSelectionViewModel()
    private let disposeBag = DisposeBag()
    private let viewWillAppearRelay = PublishRelay<Void>()
    private let cameraButtonTappedRelay = PublishRelay<Void>()
    private let libraryButtonTappedRelay = PublishRelay<Void>()
    private let photoSelectedRelay = PublishRelay<PHAsset>()
    private let filePickerButtonTappedRelay = PublishRelay<Void>()
    private let imagePickerResultRelay = PublishRelay<(ImageSourceData, CLLocation?, Date?, MediaSource)>()
    private let albumSelectedRelay = PublishRelay<Int>()

    // MARK: - Album Selector Bar

    private let albumSelectorBar: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()

    private let albumTitleButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.baseForegroundColor = .label
        config.image = UIImage(systemName: "chevron.down")
        config.imagePlacement = .trailing
        config.imagePadding = 4
        config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 10, weight: .medium)
        config.contentInsets = .zero
        let button = UIButton(configuration: config)
        return button
    }()

    private let albumCountLabel: UILabel = {
        let label = UILabel()
        label.font = .typography(.caption)
        label.textColor = .token(.textSecondary)
        return label
    }()

    // MARK: - Limited Banner

    private let limitedBannerContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .token(.textSecondary).withAlphaComponent(0.1)
        view.isHidden = true
        return view
    }()

    private let bannerInfoIcon: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "info.circle"))
        iv.tintColor = .token(.textSecondary)
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let bannerLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("media_selection.limited_banner", comment: "")
        label.font = .typography(.caption)
        label.textColor = .token(.textSecondary)
        label.numberOfLines = 0
        return label
    }()

    private let settingsLinkButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(NSLocalizedString("media_selection.allow_all_photos", comment: ""), for: .normal)
        button.titleLabel?.font = .typography(.caption)
        button.setTitleColor(.token(.accent), for: .normal)
        button.contentHorizontalAlignment = .center
        return button
    }()

    // MARK: - Album Overlay

    private let dimView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        view.alpha = 0
        view.isHidden = true
        return view
    }()

    private let albumListOverlay = AlbumListOverlayView()

    // MARK: - Collection View

    private lazy var collectionView: UICollectionView = {
        let layout = GridLayout(numberOfColumns: 3, cellSpacing: 2, minColumnWidth: 110)

        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.showsVerticalScrollIndicator = false
        cv.showsHorizontalScrollIndicator = false
        cv.register(MediaSelectionCell.self, forCellWithReuseIdentifier: "PhotoSelectionCell")
        cv.register(ActionCell.self, forCellWithReuseIdentifier: "ActionCell")
        return cv
    }()

    var onMediaSelected: ((ImageSourceData, CLLocation?, Date?) -> Void)?
    private let imageManager = PHCachingImageManager()
    private var isObserverRegistered = false
    private var isAlbumListVisible = false
    private var currentSelectedAlbumIndex = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        bind()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        if status == .authorized || status == .limited {
            registerPhotoLibraryChangeObserverIfNeeded()
        }
        viewWillAppearRelay.accept(())
    }

    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }

    private func registerPhotoLibraryChangeObserverIfNeeded() {
        guard !isObserverRegistered else { return }
        PHPhotoLibrary.shared().register(self)
        isObserverRegistered = true
    }

    // MARK: - Bind

    private func bind() {
        let input = MediaSelectionViewModel.Input(
            viewWillAppear: viewWillAppearRelay.asObservable(),
            cameraButtonTapped: cameraButtonTappedRelay.asObservable(),
            libraryButtonTapped: libraryButtonTappedRelay.asObservable(),
            filePickerButtonTapped: filePickerButtonTappedRelay.asObservable(),
            photoSelected: photoSelectedRelay.asObservable(),
            imagePickerResult: imagePickerResultRelay.asObservable(),
            albumSelected: albumSelectedRelay.asObservable()
        )

        let output = viewModel.transform(input: input)

        let dataSource = RxCollectionViewSectionedReloadDataSource<SectionModel<String, MediaCollectionItem>>(
            configureCell: { [weak self] _, collectionView, indexPath, item in
                guard let self = self else { return UICollectionViewCell() }

                switch item {
                case .action(let icon, let title, _):
                    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ActionCell", for: indexPath) as! ActionCell
                    cell.configure(icon: icon, title: title)
                    return cell
                case .photo(let asset):
                    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoSelectionCell", for: indexPath) as! MediaSelectionCell
                    cell.configure(with: asset, imageManager: self.imageManager)
                    return cell
                }
            }
        )

        Observable.combineLatest(
            output.showActionButtons.asObservable(),
            output.photos.asObservable(),
            output.permissionStatus.asObservable()
        )
            .map { showButtons, photos, status -> [SectionModel<String, MediaCollectionItem>] in
                var sections: [SectionModel<String, MediaCollectionItem>] = []

                var actionItems: [MediaCollectionItem] = []

                actionItems.append(.action(
                    icon: "camera.fill",
                    title: NSLocalizedString("media_selection.camera", comment: ""),
                    type: .camera
                ))

                if status == .limited {
                    actionItems.append(.action(
                        icon: "photo.on.rectangle",
                        title: NSLocalizedString("media_selection.add_photos", comment: ""),
                        type: .library
                    ))
                }

                actionItems.append(.action(
                    icon: "folder",
                    title: NSLocalizedString("media_selection.file", comment: ""),
                    type: .filePicker
                ))

                sections.append(SectionModel(model: "actions", items: actionItems))

                let photoItems = photos.map { MediaCollectionItem.photo(asset: $0) }
                sections.append(SectionModel(model: "photos", items: photoItems))

                return sections
            }
            .bind(to: collectionView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)

        collectionView.rx.modelSelected(MediaCollectionItem.self)
            .bind(with: self) { owner, item in
                switch item {
                case .action(_, _, let type):
                    switch type {
                    case .camera:
                        owner.cameraButtonTappedRelay.accept(())
                    case .library:
                        owner.libraryButtonTappedRelay.accept(())
                    case .filePicker:
                        owner.filePickerButtonTappedRelay.accept(())
                    }
                case .photo(let asset):
                    owner.photoSelectedRelay.accept(asset)
                }
            }
            .disposed(by: disposeBag)

        // Album title & count
        output.currentAlbumTitle
            .drive(with: self) { owner, title in
                var attributed = AttributedString(title)
                attributed.font = UIFont.typography(.label)
                owner.albumTitleButton.configuration?.attributedTitle = attributed
            }
            .disposed(by: disposeBag)

        output.currentAlbumCount
            .drive(with: self) { owner, count in
                owner.albumCountLabel.text = String(
                    format: NSLocalizedString("media_selection.photo_count", comment: ""),
                    count
                )
            }
            .disposed(by: disposeBag)

        // Permission-based limited banner
        output.permissionStatus
            .drive(with: self) { owner, status in
                owner.limitedBannerContainer.isHidden = status != .limited
            }
            .disposed(by: disposeBag)

        // Album list overlay — bind albums to tableView
        output.albums
            .drive(with: self) { owner, albums in
                owner.albumListOverlay.updateHeight(for: albums.count)
            }
            .disposed(by: disposeBag)

        output.albums
            .drive(albumListOverlay.tableView.rx.items(
                cellIdentifier: AlbumListCell.identifier,
                cellType: AlbumListCell.self
            )) { [weak self] index, album, cell in
                guard let self = self else { return }
                cell.configure(
                    with: album,
                    isSelected: index == self.currentSelectedAlbumIndex,
                    imageManager: self.imageManager
                )
            }
            .disposed(by: disposeBag)

        albumListOverlay.tableView.rx.itemSelected
            .bind(with: self) { owner, indexPath in
                owner.currentSelectedAlbumIndex = indexPath.row
                owner.albumSelectedRelay.accept(indexPath.row)
                owner.toggleAlbumList()
            }
            .disposed(by: disposeBag)

        // Album selector button tap
        albumTitleButton.rx.tap
            .bind(with: self) { owner, _ in
                owner.toggleAlbumList()
            }
            .disposed(by: disposeBag)

        // Dim view tap → close
        let dimTap = UITapGestureRecognizer()
        dimView.addGestureRecognizer(dimTap)
        dimTap.rx.event
            .bind(with: self) { owner, _ in
                if owner.isAlbumListVisible {
                    owner.toggleAlbumList()
                }
            }
            .disposed(by: disposeBag)

        // Settings link button
        settingsLinkButton.rx.tap
            .bind(with: self) { _, _ in
                guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                UIApplication.shared.open(url)
            }
            .disposed(by: disposeBag)

        // Standard outputs
        output.showCamera
            .drive(with: self) { owner, _ in
                owner.presentCamera()
            }
            .disposed(by: disposeBag)

        output.showPHPicker
            .drive(with: self) { owner, _ in
                owner.presentPHPicker()
            }
            .disposed(by: disposeBag)

        output.showFilePicker
            .drive(with: self) { owner, _ in
                owner.presentFilePicker()
            }
            .disposed(by: disposeBag)

        output.showCameraPermissionAlert
            .drive(with: self) { owner, _ in
                PermissionService.shared.showPermissionAlert(for: .camera, from: owner)
            }
            .disposed(by: disposeBag)

        output.showPhotoPermissionAlert
            .drive(with: self) { owner, _ in
                PermissionService.shared.showPermissionAlert(for: .photoLibrary, from: owner)
            }
            .disposed(by: disposeBag)

        output.requestCameraPermission
            .drive(with: self) { owner, _ in
                PermissionService.shared.requestPermission(for: .camera, from: owner) { [weak owner] status in
                    guard let owner = owner else { return }
                    if status == .authorized {
                        owner.presentCamera()
                    } else {
                        PermissionService.shared.showPermissionAlert(for: .camera, from: owner)
                    }
                }
            }
            .disposed(by: disposeBag)

        output.requestPhotoPermission
            .drive(with: self) { owner, _ in
                PermissionService.shared.requestPermission(for: .photoLibrary, from: owner) { [weak owner] status in
                    guard let owner = owner else { return }
                    owner.registerPhotoLibraryChangeObserverIfNeeded()
                    owner.viewWillAppearRelay.accept(())
                }
            }
            .disposed(by: disposeBag)

        output.showLimitedLibraryPicker
            .drive(with: self) { owner, _ in
                PHPhotoLibrary.shared().presentLimitedLibraryPicker(from: owner)
            }
            .disposed(by: disposeBag)

        output.selectedMedia
            .drive(with: self) { owner, media in
                owner.dismiss(animated: true) {
                    owner.onMediaSelected?(media.0, media.1, media.2)
                }
            }
            .disposed(by: disposeBag)
    }

    // MARK: - Album List Toggle

    private func toggleAlbumList() {
        isAlbumListVisible.toggle()

        if isAlbumListVisible {
            dimView.isHidden = false
            albumListOverlay.isHidden = false
        }

        UIView.animate(withDuration: 0.25, animations: { [weak self] in
            guard let self = self else { return }
            self.dimView.alpha = self.isAlbumListVisible ? 1 : 0
            self.albumListOverlay.alpha = self.isAlbumListVisible ? 1 : 0

            let rotation: CGAffineTransform = self.isAlbumListVisible
                ? CGAffineTransform(rotationAngle: .pi)
                : .identity
            self.albumTitleButton.imageView?.transform = rotation
        }, completion: { [weak self] _ in
            guard let self = self else { return }
            if !self.isAlbumListVisible {
                self.dimView.isHidden = true
                self.albumListOverlay.isHidden = true
            }
        })
    }

    // MARK: - Present Helpers

    private func presentCamera() {
        let cameraVC = CameraViewController()
        cameraVC.modalPresentationStyle = .fullScreen
        cameraVC.onPhotoCaptured = { [weak self] imageSource in
            self?.imagePickerResultRelay.accept((imageSource, nil, Date(), .camera))
        }
        present(cameraVC, animated: true)
    }

    private func presentFilePicker() {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.image])
        picker.delegate = self
        picker.allowsMultipleSelection = false
        present(picker, animated: true)
    }

    private func presentPHPicker() {
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.selectionLimit = 1
        configuration.filter = .images

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
    }

    // MARK: - Configure UI

    private func configureUI() {
        view.applyGradient(.subtle)

        let titleLabel = UILabel()
        titleLabel.text = NSLocalizedString("media_selection.title", comment: "")
        titleLabel.font = .typography(.label)
        titleLabel.textColor = .label
        navigationItem.titleView = titleLabel

        let closeButton = UIBarButtonItem(
            title: NSLocalizedString("common.cancel", comment: ""),
            style: .plain,
            target: self,
            action: #selector(closeTapped)
        )
        closeButton.setTitleTextAttributes([.font: UIFont.typography(.label)], for: .normal)
        navigationItem.leftBarButtonItem = closeButton

        // Album selector bar
        let albumBarStack = UIStackView(arrangedSubviews: [albumTitleButton, albumCountLabel])
        albumBarStack.axis = .horizontal
        albumBarStack.spacing = 8
        albumBarStack.alignment = .center

        albumSelectorBar.addSubview(albumBarStack)
        albumBarStack.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
        }

        // Limited banner — centered layout
        let bannerTopRow = UIStackView(arrangedSubviews: [bannerInfoIcon, bannerLabel])
        bannerTopRow.axis = .horizontal
        bannerTopRow.spacing = 6
        bannerTopRow.alignment = .center

        bannerInfoIcon.snp.makeConstraints { make in
            make.width.height.equalTo(16)
        }

        let bannerStack = UIStackView(arrangedSubviews: [bannerTopRow, settingsLinkButton])
        bannerStack.axis = .vertical
        bannerStack.spacing = 0
        bannerStack.alignment = .center

        limitedBannerContainer.addSubview(bannerStack)
        bannerStack.snp.makeConstraints { make in
            make.centerX.centerY.equalToSuperview()
            make.top.greaterThanOrEqualToSuperview().inset(10)
            make.bottom.lessThanOrEqualToSuperview().inset(10)
            make.leading.greaterThanOrEqualToSuperview().inset(16)
            make.trailing.lessThanOrEqualToSuperview().inset(16)
        }

        // Main stack: albumSelectorBar + limitedBanner + collectionView
        let contentStack = UIStackView(arrangedSubviews: [
            albumSelectorBar, limitedBannerContainer, collectionView
        ])
        contentStack.axis = .vertical

        albumSelectorBar.snp.makeConstraints { make in
            make.height.equalTo(44)
        }

        limitedBannerContainer.snp.makeConstraints { make in
            make.height.equalTo(52)
        }

        view.addSubview(contentStack)
        contentStack.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }

        // Dim + overlay (above everything)
        view.addSubview(dimView)
        dimView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        albumListOverlay.alpha = 0
        albumListOverlay.isHidden = true
        view.addSubview(albumListOverlay)
        albumListOverlay.snp.makeConstraints { make in
            make.top.equalTo(albumSelectorBar.snp.bottom)
            make.leading.trailing.equalToSuperview()
        }
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }
}

// MARK: - UIDocumentPickerDelegate

extension MediaSelectionViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }

        let didAccess = url.startAccessingSecurityScopedResource()

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            defer {
                if didAccess { url.stopAccessingSecurityScopedResource() }
            }

            guard let data = try? Data(contentsOf: url),
                  let result = ImageFormatConverter.createImageSourceData(from: data) else {
                return
            }

            DispatchQueue.main.async {
                self?.imagePickerResultRelay.accept((
                    result.imageSource,
                    result.metadata.location,
                    result.metadata.date,
                    .filePicker
                ))
            }
        }
    }
}

// MARK: - PHPickerViewControllerDelegate

extension MediaSelectionViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)

        guard let result = results.first else { return }
        let itemProvider = result.itemProvider

        let asset = result.assetIdentifier.flatMap { identifier in
            PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil).firstObject
        }
        let assetDate = asset?.creationDate
        let assetLocation = asset?.location

        let typeIdentifiers = itemProvider.registeredTypeIdentifiers
        let preferredType = typeIdentifiers.first ?? "public.image"

        itemProvider.loadFileRepresentation(forTypeIdentifier: preferredType) { [weak self] url, error in
            guard let url = url, error == nil else {
                self?.loadImageFallback(from: itemProvider)
                return
            }

            do {
                let data = try Data(contentsOf: url)
                guard let result = ImageFormatConverter.createImageSourceData(from: data, utiHint: preferredType) else {
                    self?.loadImageFallback(from: itemProvider)
                    return
                }

                let finalDate = assetDate ?? result.metadata.date
                let finalLocation = assetLocation ?? result.metadata.location

                DispatchQueue.main.async {
                    self?.imagePickerResultRelay.accept((result.imageSource, finalLocation, finalDate, .library))
                }
            } catch {
                self?.loadImageFallback(from: itemProvider)
            }
        }
    }

    private func loadImageFallback(from itemProvider: NSItemProvider) {
        if itemProvider.canLoadObject(ofClass: UIImage.self) {
            itemProvider.loadObject(ofClass: UIImage.self) { [weak self] image, _ in
                DispatchQueue.main.async {
                    if let image = image as? UIImage {
                        let imageSource = ImageSourceData(image: image)
                        self?.imagePickerResultRelay.accept((imageSource, nil, nil, .library))
                    }
                }
            }
        }
    }
}

// MARK: - PHPhotoLibraryChangeObserver

extension MediaSelectionViewController: PHPhotoLibraryChangeObserver {
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        DispatchQueue.main.async { [weak self] in
            self?.viewWillAppearRelay.accept(())
        }
    }
}

// MARK: - ActionCell

final class ActionCell: UICollectionViewCell {
    private let iconImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.tintColor = .token(.accent)
        return iv
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .typography(.caption)
        label.textAlignment = .center
        label.textColor = .label
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .secondarySystemBackground

        contentView.addSubview(iconImageView)
        contentView.addSubview(titleLabel)

        iconImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(40)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(iconImageView.snp.bottom).offset(8)
            make.horizontalEdges.equalToSuperview().inset(4)
        }
    }

    func configure(icon: String, title: String) {
        iconImageView.image = UIImage(systemName: icon)
        titleLabel.text = title
    }
}
