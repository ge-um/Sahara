//
//  MediaSelectionViewController.swift
//  Sahara
//
//  Created by 금가경 on 9/26/25.
//

import AVFoundation
import Photos
import PhotosUI
import SnapKit
import UIKit

final class MediaSelectionViewController: UIViewController {
    private enum Section: Int, CaseIterable {
        case actions = 0
        case photos = 1
    }

    private enum ActionItem: Int, CaseIterable {
        case camera = 0
        case library = 1
    }

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let spacing: CGFloat = 2
        let width = (view.bounds.width - spacing * 4) / 3
        layout.itemSize = CGSize(width: width, height: width)
        layout.minimumInteritemSpacing = spacing
        layout.minimumLineSpacing = spacing
        layout.sectionInset = UIEdgeInsets(top: spacing, left: spacing, bottom: spacing, right: spacing)

        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.showsVerticalScrollIndicator = false
        cv.showsHorizontalScrollIndicator = false
        cv.register(PhotoSelectionCell.self, forCellWithReuseIdentifier: "PhotoSelectionCell")
        cv.register(ActionCell.self, forCellWithReuseIdentifier: "ActionCell")
        cv.delegate = self
        cv.dataSource = self
        return cv
    }()

    var onMediaSelected: ((UIImage, CLLocation?, Date?) -> Void)?
    private var photos: [PHAsset] = []
    private let imageManager = PHCachingImageManager()
    private var isObserverRegistered = false

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        if status == .authorized || status == .limited {
            registerPhotoLibraryChangeObserverIfNeeded()
            fetchPhotos()
        }
        collectionView.reloadData()
    }

    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }

    private func configureUI() {
        view.applyGradient(.grayGradient)

        // 커스텀 타이틀 뷰로 폰트 적용
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


    private func fetchPhotos() {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

        let results = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        photos = []
        results.enumerateObjects { asset, _, _ in
            self.photos.append(asset)
        }

        collectionView.reloadData()
    }


    private func openCamera() {
        let status = PermissionManager.shared.checkPermission(for: .camera)

        switch status {
        case .authorized:
            presentCamera()
        case .denied:
            PermissionManager.shared.showPermissionAlert(for: .camera, from: self)
        case .notDetermined:
            PermissionManager.shared.requestPermission(for: .camera, from: self) { [weak self] status in
                guard let self = self else { return }
                if status == .authorized {
                    self.presentCamera()
                } else {
                    PermissionManager.shared.showPermissionAlert(for: .camera, from: self)
                }
            }
        case .limited:
            break
        }
    }

    private func presentCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else { return }

        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = self
        present(picker, animated: true)
    }


    private func openPHPicker() {
        let status = PermissionManager.shared.checkPermission(for: .photoLibrary)

        switch status {
        case .authorized:
            registerPhotoLibraryChangeObserverIfNeeded()
            presentPHPicker()
            fetchPhotos()
        case .limited:
            registerPhotoLibraryChangeObserverIfNeeded()
            PHPhotoLibrary.shared().presentLimitedLibraryPicker(from: self)
            fetchPhotos()
        case .denied:
            PermissionManager.shared.showPermissionAlert(for: .photoLibrary, from: self)
        case .notDetermined:
            PermissionManager.shared.requestPermission(for: .photoLibrary, from: self) { [weak self] status in
                guard let self = self else { return }
                self.registerPhotoLibraryChangeObserverIfNeeded()
                switch status {
                case .authorized:
                    self.fetchPhotos()
                case .limited:
                    self.fetchPhotos()
                case .denied:
                    PermissionManager.shared.showPermissionAlert(for: .photoLibrary, from: self)
                case .notDetermined:
                    break
                }
            }
        }
    }

    private func registerPhotoLibraryChangeObserverIfNeeded() {
        guard !isObserverRegistered else { return }
        PHPhotoLibrary.shared().register(self)
        isObserverRegistered = true
    }

    private func presentPHPicker() {
        var configuration = PHPickerConfiguration()
        configuration.selectionLimit = 1
        configuration.filter = .images

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
    }
}

extension MediaSelectionViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 {
            let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
            return status == .authorized ? 1 : 2
        } else {
            return photos.count
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.section == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ActionCell", for: indexPath) as! ActionCell
            let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)

            if status == .authorized {
                cell.configure(icon: "camera.fill", title: NSLocalizedString("media_selection.camera", comment: ""))
            } else {
                if indexPath.item == 0 {
                    cell.configure(icon: "camera.fill", title: NSLocalizedString("media_selection.camera", comment: ""))
                } else {
                    cell.configure(icon: "photo.on.rectangle", title: NSLocalizedString("media_selection.library", comment: ""))
                }
            }
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoSelectionCell", for: indexPath) as! PhotoSelectionCell
            let asset = photos[indexPath.item]
            cell.configure(with: asset, imageManager: imageManager)
            return cell
        }
    }
}

extension MediaSelectionViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)

            if status == .authorized {
                openCamera()
            } else {
                if indexPath.item == 0 {
                    openCamera()
                } else {
                    openPHPicker()
                }
            }
        } else {
            let asset = photos[indexPath.item]
            let options = PHImageRequestOptions()
            options.isSynchronous = false
            options.deliveryMode = .highQualityFormat

            imageManager.requestImage(
                for: asset,
                targetSize: PHImageManagerMaximumSize,
                contentMode: .aspectFit,
                options: options
            ) { [weak self] image, _ in
                if let image = image {
                    AnalyticsManager.shared.logPhotoSourceSelected(source: "gallery")
                    let location = asset.location
                    let date = asset.creationDate
                    self?.onMediaSelected?(image, location, date)
                    self?.dismiss(animated: true)
                }
            }
        }
    }
}

extension MediaSelectionViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true)

        if let image = info[.originalImage] as? UIImage {
            AnalyticsManager.shared.logPhotoSourceSelected(source: "camera")
            onMediaSelected?(image, nil, nil)
            dismiss(animated: true)
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}

extension MediaSelectionViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)

        guard let itemProvider = results.first?.itemProvider else { return }

        if itemProvider.canLoadObject(ofClass: UIImage.self) {
            itemProvider.loadObject(ofClass: UIImage.self) { [weak self] image, _ in
                DispatchQueue.main.async {
                    if let image = image as? UIImage {
                        AnalyticsManager.shared.logPhotoSourceSelected(source: "library")
                        self?.onMediaSelected?(image, nil, nil)
                        self?.dismiss(animated: true)
                    }
                }
            }
        }
    }
}

extension MediaSelectionViewController: PHPhotoLibraryChangeObserver {
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        DispatchQueue.main.async { [weak self] in
            self?.fetchPhotos()
        }
    }
}

final class ActionCell: UICollectionViewCell {
    private let iconImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.tintColor = ColorSystem.gradientBlue
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

final class PhotoSelectionCell: UICollectionViewCell {
    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    func configure(with asset: PHAsset, imageManager: PHCachingImageManager) {
        let size = CGSize(width: 200, height: 200)
        imageManager.requestImage(
            for: asset,
            targetSize: size,
            contentMode: .aspectFill,
            options: nil
        ) { [weak self] image, _ in
            self?.imageView.image = image
        }
    }
}
