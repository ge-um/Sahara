//
//  GalleryViewController.swift
//  Sahara
//
//  Created by 금가경 on 9/26/25.
//

import PhotosUI
import RealmSwift
import RxCocoa
import RxSwift
import RxDataSources
import SnapKit
import UIKit
import MapKit

final class GalleryViewController: UIViewController {
    private let customNavigationBar = CustomNavigationBar()

    private let emptyStateView = EmptyStateView()

    private let viewTypeButtonStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fill
        stackView.spacing = 4
        return stackView
    }()

    private lazy var dateButton: GradientButton = {
        let button = GradientButton(title: NSLocalizedString("gallery.date_view", comment: ""))
        button.tag = 0
        return button
    }()

    private lazy var locationButton: GradientButton = {
        let button = GradientButton(title: NSLocalizedString("gallery.location_view", comment: ""))
        button.tag = 1
        return button
    }()

    private lazy var themeButton: GradientButton = {
        let button = GradientButton(title: NSLocalizedString("gallery.theme_view", comment: ""))
        button.tag = 2
        return button
    }()

    private lazy var folderButton: GradientButton = {
        let button = GradientButton(title: NSLocalizedString("gallery.folder_view", comment: ""))
        button.tag = 3
        return button
    }()
    
    private lazy var calendarContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()

    private lazy var calendarVC: CalendarViewController = {
        let vc = CalendarViewController(viewModel: viewModel)
        return vc
    }()
    
    private lazy var mapView: MKMapView = {
        let mapView = MKMapView()
        mapView.delegate = self
        mapView.layer.cornerRadius = 12
        mapView.clipsToBounds = true
        mapView.showsUserLocation = false
        return mapView
    }()

    private lazy var themeContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()

    private lazy var themeVC: ThemeViewController = {
        let vc = ThemeViewController()
        return vc
    }()

    private lazy var folderContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()

    private lazy var folderVC: FolderViewController = {
        let vc = FolderViewController()
        return vc
    }()

    private let realm = try! Realm()
    private let disposeBag = DisposeBag()
    private let viewModel: GalleryViewModel
    private let viewTypeRelay = BehaviorRelay<GalleryViewType>(value: .date)
    
    init(viewModel: GalleryViewModel) {
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
        setupCalendarView()
        setupMapView()
        setupThemeView()
        setupFolderView()
        setupCustomNavigationBar()
        bind()
    }

    private func setupCalendarView() {
        addChild(calendarVC)
        calendarContainerView.addSubview(calendarVC.view)
        calendarVC.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        calendarVC.didMove(toParent: self)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateButtonStyles(selectedType: viewTypeRelay.value)
    }

    private func setupCustomNavigationBar() {
        customNavigationBar.configure(title: NSLocalizedString("common.app_name", comment: ""))
        customNavigationBar.hideLeftButton()

        customNavigationBar.addRightButton(title: "+") { [weak self] in
            self?.addButtonTapped()
        }

        emptyStateView.configure(
            message: NSLocalizedString("gallery.empty_message", comment: ""),
            buttonTitle: NSLocalizedString("gallery.empty_button", comment: "")
        )
        emptyStateView.onActionButtonTapped = { [weak self] in
            self?.addButtonTapped()
        }
    }

    @objc private func addButtonTapped() {
        let viewModel = CardInfoViewModel(editedImage: nil)
        let cardInfoVC = CardInfoViewController(viewModel: viewModel)
        let navController = UINavigationController(rootViewController: cardInfoVC)
        navController.modalPresentationStyle = .fullScreen
        present(navController, animated: true)
    }

    private func setupThemeView() {
        addChild(themeVC)
        themeContainerView.addSubview(themeVC.view)
        themeVC.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        themeVC.didMove(toParent: self)
    }

    private func setupFolderView() {
        addChild(folderVC)
        folderContainerView.addSubview(folderVC.view)
        folderVC.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        folderVC.didMove(toParent: self)
    }

    private func setupMapView() {
        mapView.register(MediaAnnotationView.self, forAnnotationViewWithReuseIdentifier: MediaAnnotation.identifier)
        mapView.register(MediaClusterAnnotationView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultClusterAnnotationViewReuseIdentifier)
    }

    private func loadMapAnnotations() {
        mapView.removeAnnotations(mapView.annotations)

        let memos = realm.objects(Card.self)
            .filter("latitude != nil AND longitude != nil")
            .filter { $0.latitude != 0 && $0.longitude != 0 }

        let annotations = Array(memos.compactMap { memo -> MediaAnnotation? in
            guard let lat = memo.latitude, let lon = memo.longitude,
                  lat != 0, lon != 0 else { return nil }
            let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            return MediaAnnotation(coordinate: coordinate, cardIds: [memo.id])
        })

        mapView.addAnnotations(annotations)

        if !annotations.isEmpty {
            mapView.showAnnotations(annotations, animated: true)
        }
    }
    
    private func configureUI() {
        view.applyGradientWithDots(.pinkToBlue, dotSize: 5, spacing: 32, dotColor: .white)

        view.addSubview(customNavigationBar)
        view.addSubview(emptyStateView)
        view.addSubview(viewTypeButtonStackView)
        viewTypeButtonStackView.addArrangedSubview(dateButton)
        viewTypeButtonStackView.addArrangedSubview(locationButton)
        viewTypeButtonStackView.addArrangedSubview(themeButton)
        viewTypeButtonStackView.addArrangedSubview(folderButton)

        view.addSubview(calendarContainerView)
        view.addSubview(mapView)
        view.addSubview(themeContainerView)
        view.addSubview(folderContainerView)

        customNavigationBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.horizontalEdges.equalToSuperview()
            make.height.equalTo(56)
        }

        emptyStateView.snp.makeConstraints { make in
            make.top.equalTo(customNavigationBar.snp.bottom)
            make.horizontalEdges.bottom.equalToSuperview()
        }

        viewTypeButtonStackView.snp.makeConstraints { make in
            make.top.equalTo(customNavigationBar.snp.bottom).offset(20)
            make.leading.equalToSuperview().offset(20)
            make.height.equalTo(36)
        }

        calendarContainerView.snp.makeConstraints { make in
            make.top.equalTo(viewTypeButtonStackView.snp.bottom).offset(20)
            make.horizontalEdges.equalToSuperview().inset(20)
            make.bottom.equalToSuperview().inset(112)
        }

        mapView.snp.makeConstraints { make in
            make.top.equalTo(viewTypeButtonStackView.snp.bottom).offset(20)
            make.horizontalEdges.equalToSuperview().inset(20)
            make.bottom.equalToSuperview().inset(112)
        }

        themeContainerView.snp.makeConstraints { make in
            make.top.equalTo(viewTypeButtonStackView.snp.bottom).offset(20)
            make.horizontalEdges.equalToSuperview().inset(20)
            make.bottom.equalToSuperview().inset(112)
        }

        folderContainerView.snp.makeConstraints { make in
            make.top.equalTo(viewTypeButtonStackView.snp.bottom).offset(20)
            make.horizontalEdges.equalToSuperview().inset(20)
            make.bottom.equalToSuperview().inset(112)
        }
    }
    
    private func bind() {
        dateButton.rx.tap
            .map { GalleryViewType.date }
            .bind(to: viewTypeRelay)
            .disposed(by: disposeBag)

        locationButton.rx.tap
            .map { GalleryViewType.location }
            .bind(to: viewTypeRelay)
            .disposed(by: disposeBag)

        themeButton.rx.tap
            .map { GalleryViewType.theme }
            .bind(to: viewTypeRelay)
            .disposed(by: disposeBag)

        folderButton.rx.tap
            .map { GalleryViewType.folder }
            .bind(to: viewTypeRelay)
            .disposed(by: disposeBag)

        viewTypeRelay
            .asObservable()
            .bind(with: self) { owner, viewType in
                owner.updateButtonStyles(selectedType: viewType)
                let viewTypeString: String
                switch viewType {
                case .date:
                    viewTypeString = "calendar"
                case .location:
                    viewTypeString = "map"
                case .theme:
                    viewTypeString = "theme"
                case .folder:
                    viewTypeString = "folder"
                }
                AnalyticsManager.shared.logGalleryViewChanged(viewType: viewTypeString)
            }
            .disposed(by: disposeBag)

        let photoSavedNotification = NotificationCenter.default.rx
            .notification(AppNotification.photoSaved.name)
            .map { _ in () }

        let photoDeletedNotification = NotificationCenter.default.rx
            .notification(AppNotification.photoDeleted.name)
            .map { _ in () }

        let viewWillAppearObservable = Observable.merge(
            rx.methodInvoked(#selector(viewWillAppear(_:))).map { _ in () },
            photoSavedNotification,
            photoDeletedNotification
        )

        let input = GalleryViewModel.Input(
            viewWillAppear: viewWillAppearObservable,
            addButtonTapped: Observable.never(),
            previousMonthTapped: Observable.never(),
            nextMonthTapped: Observable.never(),
            viewTypeSelected: viewTypeRelay.asObservable()
        )

        let output = viewModel.transform(input: input)

        Driver.combineLatest(output.isEmpty, output.selectedViewType)
            .drive(with: self) { owner, data in
                let (isEmpty, viewType) = data
                owner.emptyStateView.isHidden = !isEmpty
                owner.viewTypeButtonStackView.isHidden = isEmpty
                owner.customNavigationBar.setRightButtonHidden(isEmpty)

                if isEmpty {
                    owner.calendarContainerView.isHidden = true
                    owner.mapView.isHidden = true
                    owner.themeContainerView.isHidden = true
                    owner.folderContainerView.isHidden = true
                } else {
                    owner.calendarContainerView.isHidden = viewType != .date
                    owner.mapView.isHidden = viewType != .location
                    owner.themeContainerView.isHidden = viewType != .theme
                    owner.folderContainerView.isHidden = viewType != .folder

                    if viewType == .location {
                        owner.loadMapAnnotations()
                    } else if viewType == .theme {
                        owner.themeVC.refreshData()
                    }
                }
            }
            .disposed(by: disposeBag)

        Observable.merge(
            photoSavedNotification,
            photoDeletedNotification
        )
        .withLatestFrom(output.selectedViewType.asObservable())
        .bind(with: self) { owner, viewType in
            if viewType == .location {
                owner.loadMapAnnotations()
            } else if viewType == .theme {
                owner.themeVC.refreshData()
            }
        }
        .disposed(by: disposeBag)
    }

    private func updateButtonStyles(selectedType: GalleryViewType) {
        let buttons = [dateButton, locationButton, themeButton, folderButton]
        let types: [GalleryViewType] = [.date, .location, .theme, .folder]

        for (button, type) in zip(buttons, types) {
            if type == selectedType {
                button.setGradient(.royalBlue, isSelected: true)
            } else {
                button.setGradient(.whiteToGray, isSelected: false)
            }
        }
    }

}

extension GalleryViewController: PHPickerViewControllerDelegate {

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)

        guard let itemProvider = results.first?.itemProvider else { return }

        if itemProvider.canLoadObject(ofClass: UIImage.self) {
            itemProvider.loadObject(ofClass: UIImage.self) { image, error in
                DispatchQueue.main.async {
                    guard let image = image as? UIImage else { return }

                    let stickerViewModel = MediaEditorViewModel(originalImage: image)
                    let stickerVC = MediaEditorViewController(viewModel: stickerViewModel)
                    let nav = UINavigationController(rootViewController: stickerVC)
                    nav.modalPresentationStyle = .fullScreen
                    self.present(nav, animated: true)
                }
            }
        }
    }
}

extension GalleryViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let cluster = annotation as? MKClusterAnnotation {
            var clusterView = mapView.dequeueReusableAnnotationView(withIdentifier: MKMapViewDefaultClusterAnnotationViewReuseIdentifier) as? MediaClusterAnnotationView

            if clusterView == nil {
                clusterView = MediaClusterAnnotationView(annotation: annotation, reuseIdentifier: MKMapViewDefaultClusterAnnotationViewReuseIdentifier)
            } else {
                clusterView?.annotation = annotation
            }

            let photoAnnotations = cluster.memberAnnotations.compactMap { $0 as? MediaAnnotation }
            var representativeImage: UIImage?
            var isLocked = false

            let allPhotos = photoAnnotations.flatMap { annotation in
                annotation.cardIds.compactMap { realm.object(ofType: Card.self, forPrimaryKey: $0) }
            }

            let sortedPhotos = allPhotos.sorted { !$0.isLocked && $1.isLocked }

            if let firstPhoto = sortedPhotos.first {
                representativeImage = UIImage(data: firstPhoto.editedImageData)
                isLocked = firstPhoto.isLocked
            }

            clusterView?.configure(with: cluster.memberAnnotations.count, image: representativeImage, isLocked: isLocked)
            return clusterView
        }

        guard let photoAnnotation = annotation as? MediaAnnotation else { return nil }

        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: MediaAnnotation.identifier) as? MediaAnnotationView

        if annotationView == nil {
            annotationView = MediaAnnotationView(annotation: annotation, reuseIdentifier: MediaAnnotation.identifier)
        } else {
            annotationView?.annotation = annotation
        }

        annotationView?.clusteringIdentifier = MediaAnnotation.clusterID

        let photos = photoAnnotation.cardIds.compactMap { realm.object(ofType: Card.self, forPrimaryKey: $0) }
        let sortedPhotos = photos.sorted { !$0.isLocked && $1.isLocked }

        if let firstPhoto = sortedPhotos.first,
           let image = UIImage(data: firstPhoto.editedImageData) {
            annotationView?.configure(with: image, isLocked: firstPhoto.isLocked)
        }

        return annotationView
    }

    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        mapView.deselectAnnotation(view.annotation, animated: false)

        if let cluster = view.annotation as? MKClusterAnnotation {
            let photoAnnotations = cluster.memberAnnotations.compactMap { $0 as? MediaAnnotation }
            let allPhotoIds = photoAnnotations.flatMap { $0.cardIds }
            let allPhotos = allPhotoIds.compactMap { realm.object(ofType: Card.self, forPrimaryKey: $0) }

            if !allPhotos.isEmpty {
                showGallery(for: allPhotos)
            }
        }
        else if let photoAnnotation = view.annotation as? MediaAnnotation {
            let cards = photoAnnotation.cardIds.compactMap { realm.object(ofType: Card.self, forPrimaryKey: $0) }
            showGallery(for: cards)
        }
    }

    private func showGallery(for cards: [Card]) {
        let photoCount = cards.count
        AnalyticsManager.shared.logMapLocationViewed(cardsCount: photoCount)
        let title = String(format: NSLocalizedString("common.photo_count", comment: ""), photoCount)
        let galleryVC = CardListViewController(cards: cards, themeCategory: .others, customTitle: title)
        navigationController?.pushViewController(galleryVC, animated: true)
    }
}
