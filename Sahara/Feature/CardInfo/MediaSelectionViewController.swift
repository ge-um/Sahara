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

enum MediaCollectionItem {
    case action(icon: String, title: String, type: ActionType)
    case photo(asset: PHAsset)
}

enum ActionType {
    case camera
    case library
}

final class MediaSelectionViewController: UIViewController {
    private let viewModel = MediaSelectionViewModel()
    private let disposeBag = DisposeBag()
    private let viewWillAppearRelay = PublishRelay<Void>()
    private let cameraButtonTappedRelay = PublishRelay<Void>()
    private let libraryButtonTappedRelay = PublishRelay<Void>()
    private let photoSelectedRelay = PublishRelay<PHAsset>()
    private let imagePickerResultRelay = PublishRelay<(ImageSourceData, CLLocation?, Date?, MediaSource)>()

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

    private func bind() {
        let input = MediaSelectionViewModel.Input(
            viewWillAppear: viewWillAppearRelay.asObservable(),
            cameraButtonTapped: cameraButtonTappedRelay.asObservable(),
            libraryButtonTapped: libraryButtonTappedRelay.asObservable(),
            photoSelected: photoSelectedRelay.asObservable(),
            imagePickerResult: imagePickerResultRelay.asObservable()
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

        Observable.combineLatest(output.showActionButtons.asObservable(), output.photos.asObservable())
            .map { showButtons, photos -> [SectionModel<String, MediaCollectionItem>] in
                var sections: [SectionModel<String, MediaCollectionItem>] = []

                let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
                var actionItems: [MediaCollectionItem] = []

                actionItems.append(.action(
                    icon: "camera.fill",
                    title: NSLocalizedString("media_selection.camera", comment: ""),
                    type: .camera
                ))
                if status != .authorized {
                    actionItems.append(.action(
                        icon: "photo.on.rectangle",
                        title: NSLocalizedString("media_selection.library", comment: ""),
                        type: .library
                    ))
                }

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
                    }
                case .photo(let asset):
                    owner.photoSelectedRelay.accept(asset)
                }
            }
            .disposed(by: disposeBag)

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

        output.showCameraPermissionAlert
            .drive(with: self) { owner, _ in
                PermissionManager.shared.showPermissionAlert(for: .camera, from: owner)
            }
            .disposed(by: disposeBag)

        output.showPhotoPermissionAlert
            .drive(with: self) { owner, _ in
                PermissionManager.shared.showPermissionAlert(for: .photoLibrary, from: owner)
            }
            .disposed(by: disposeBag)

        output.requestCameraPermission
            .drive(with: self) { owner, _ in
                PermissionManager.shared.requestPermission(for: .camera, from: owner) { [weak owner] status in
                    guard let owner = owner else { return }
                    if status == .authorized {
                        owner.presentCamera()
                    } else {
                        PermissionManager.shared.showPermissionAlert(for: .camera, from: owner)
                    }
                }
            }
            .disposed(by: disposeBag)

        output.requestPhotoPermission
            .drive(with: self) { owner, _ in
                PermissionManager.shared.requestPermission(for: .photoLibrary, from: owner) { [weak owner] status in
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

    private func presentCamera() {
        let cameraVC = CameraViewController()
        cameraVC.modalPresentationStyle = .fullScreen
        cameraVC.onPhotoCaptured = { [weak self] imageSource in
            self?.imagePickerResultRelay.accept((imageSource, nil, Date(), .camera))
        }
        present(cameraVC, animated: true)
    }

    private func presentPHPicker() {
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.selectionLimit = 1
        configuration.filter = .images

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
    }

    private func configureUI() {
        view.applyGradient(.subtle)

        let titleLabel = UILabel()
        titleLabel.text = NSLocalizedString("media_selection.title", comment: "")
        titleLabel.font = FontSystem.galmuriMono(size: 16)
        titleLabel.textColor = .label
        navigationItem.titleView = titleLabel

        let closeButton = UIBarButtonItem(
            title: NSLocalizedString("common.cancel", comment: ""),
            style: .plain,
            target: self,
            action: #selector(closeTapped)
        )
        closeButton.setTitleTextAttributes([.font: FontSystem.galmuriMono(size: 14)], for: .normal)
        navigationItem.leftBarButtonItem = closeButton

        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }
}

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
                guard let image = UIImage(data: data) else {
                    self?.loadImageFallback(from: itemProvider)
                    return
                }

                let format = ImageFormatHelper.detectFromUTI(preferredType)
                    ?? ImageFormatHelper.detect(from: data)

                let exifMetadata = EXIFMetadataExtractor.extract(from: data)
                let finalDate = assetDate ?? exifMetadata.date
                let finalLocation = assetLocation ?? exifMetadata.location

                DispatchQueue.main.async {
                    let imageSource = ImageSourceData(
                        image: image,
                        originalData: data,
                        format: format
                    )
                    self?.imagePickerResultRelay.accept((imageSource, finalLocation, finalDate, .library))
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

extension MediaSelectionViewController: PHPhotoLibraryChangeObserver {
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        DispatchQueue.main.async { [weak self] in
            self?.viewWillAppearRelay.accept(())
        }
    }
}

final class ActionCell: UICollectionViewCell {
    private let iconImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.tintColor = .token(.accent)
        return iv
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = FontSystem.galmuriMono(size: 12)
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

