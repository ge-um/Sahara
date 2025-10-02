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
    
    private let calendarHeaderView = CalendarHeaderView()
    
    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout())
        collectionView.register(CalendarCell.self, forCellWithReuseIdentifier: CalendarCell.identifier)
        collectionView.backgroundColor = .clear
        collectionView.isScrollEnabled = false
        return collectionView
    }()
    
    private lazy var mapView: MKMapView = {
        let mapView = MKMapView()
        mapView.delegate = self
        return mapView
    }()

    private lazy var themeContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        return view
    }()

    private lazy var themeGalleryVC: ThemeGalleryViewController = {
        let vc = ThemeGalleryViewController()
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
        setupMapView()
        setupThemeView()
        setupCustomNavigationBar()
        bind()
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
        addChild(themeGalleryVC)
        themeContainerView.addSubview(themeGalleryVC.view)
        themeGalleryVC.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        themeGalleryVC.didMove(toParent: self)
    }

    private func setupMapView() {
        mapView.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier)
        mapView.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultClusterAnnotationViewReuseIdentifier)
    }

    private func loadMapAnnotations() {
        mapView.removeAnnotations(mapView.annotations)

        let memos = realm.objects(Card.self)
            .filter("latitude != nil AND longitude != nil")
            .filter { $0.latitude != 0 && $0.longitude != 0 }

        var coordinateGroups: [String: [Card]] = [:]
        for memo in memos {
            guard let lat = memo.latitude, let lon = memo.longitude,
                  lat != 0, lon != 0 else { continue }
            let key = "\(lat),\(lon)"
            coordinateGroups[key, default: []].append(memo)
        }

        let annotations = coordinateGroups.compactMap { key, memos -> PhotoAnnotation? in
            guard let firstMemo = memos.first,
                  let lat = firstMemo.latitude,
                  let lon = firstMemo.longitude,
                  lat != 0, lon != 0 else { return nil }
            let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            return PhotoAnnotation(coordinate: coordinate, photoMemos: memos)
        }

        mapView.addAnnotations(annotations)

        if !annotations.isEmpty {
            mapView.showAnnotations(annotations, animated: true)
        }
    }
    
    private func configureUI() {
        view.applyGradientWithDots(.pinkBlue, dotSize: 5, spacing: 32, dotColor: .white)

        view.addSubview(customNavigationBar)
        view.addSubview(emptyStateView)
        view.addSubview(viewTypeButtonStackView)
        viewTypeButtonStackView.addArrangedSubview(dateButton)
        viewTypeButtonStackView.addArrangedSubview(locationButton)
        viewTypeButtonStackView.addArrangedSubview(themeButton)

        view.addSubview(calendarHeaderView)
        view.addSubview(collectionView)
        view.addSubview(mapView)
        view.addSubview(themeContainerView)

        customNavigationBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.horizontalEdges.equalToSuperview()
            make.height.equalTo(54)
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

        calendarHeaderView.snp.makeConstraints { make in
            make.top.equalTo(viewTypeButtonStackView.snp.bottom).offset(10)
            make.horizontalEdges.equalToSuperview()
            make.height.equalTo(68)
        }

        collectionView.snp.makeConstraints { make in
            make.top.equalTo(calendarHeaderView.snp.bottom)
            make.horizontalEdges.equalToSuperview().inset(24)
            make.bottom.equalToSuperview().inset(70)
        }

        mapView.snp.makeConstraints { make in
            make.top.equalTo(calendarHeaderView.snp.bottom)
            make.horizontalEdges.equalToSuperview()
            make.bottom.equalToSuperview().inset(70)
        }

        themeContainerView.snp.makeConstraints { make in
            make.top.equalTo(viewTypeButtonStackView.snp.bottom).offset(10)
            make.horizontalEdges.equalToSuperview()
            make.bottom.equalToSuperview().inset(70)
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

        viewTypeRelay
            .asObservable()
            .bind(with: self) { owner, viewType in
                owner.updateButtonStyles(selectedType: viewType)
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

        calendarHeaderView.onPreviousMonthTapped = {
            NotificationCenter.default.post(name: NSNotification.Name("PreviousMonthTapped"), object: nil)
        }

        calendarHeaderView.onNextMonthTapped = {
            NotificationCenter.default.post(name: NSNotification.Name("NextMonthTapped"), object: nil)
        }

        let previousMonthObservable = NotificationCenter.default.rx
            .notification(NSNotification.Name("PreviousMonthTapped"))
            .map { _ in () }

        let nextMonthObservable = NotificationCenter.default.rx
            .notification(NSNotification.Name("NextMonthTapped"))
            .map { _ in () }

        let input = GalleryViewModel.Input(
            viewWillAppear: viewWillAppearObservable,
            addButtonTapped: Observable.never(),
            previousMonthTapped: previousMonthObservable,
            nextMonthTapped: nextMonthObservable,
            viewTypeSelected: viewTypeRelay.asObservable()
        )

        let output = viewModel.transform(input: input)
        
        let dataSource = RxCollectionViewSectionedReloadDataSource<CalendarSection>(
            configureCell: { _, collectionView, indexPath, item in
                guard let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: CalendarCell.identifier,
                    for: indexPath
                ) as? CalendarCell else {
                    return UICollectionViewCell()
                }
                cell.configure(with: item)
                return cell
            }
        )
        
        output.calendarItems
            .map { [CalendarSection(items: $0)] }
            .drive(collectionView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
        
        output.currentMonthTitle
            .drive(with: self) { owner, monthTitle in
                owner.calendarHeaderView.configure(monthTitle: monthTitle)
            }
            .disposed(by: disposeBag)

        Driver.combineLatest(output.isEmpty, output.selectedViewType)
            .drive(with: self) { owner, data in
                let (isEmpty, viewType) = data
                owner.emptyStateView.isHidden = !isEmpty
                owner.viewTypeButtonStackView.isHidden = isEmpty
                owner.customNavigationBar.setRightButtonHidden(isEmpty)

                if isEmpty {
                    owner.calendarHeaderView.isHidden = true
                    owner.collectionView.isHidden = true
                    owner.mapView.isHidden = true
                    owner.themeContainerView.isHidden = true
                } else {
                    owner.calendarHeaderView.isHidden = viewType != .date
                    owner.collectionView.isHidden = viewType != .date
                    owner.mapView.isHidden = viewType != .location
                    owner.themeContainerView.isHidden = viewType != .theme

                    if viewType == .location {
                        owner.loadMapAnnotations()
                    } else if viewType == .theme {
                        owner.themeGalleryVC.refreshData()
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
                owner.themeGalleryVC.refreshData()
            }
        }
        .disposed(by: disposeBag)
        
        collectionView.rx.modelSelected(DayItem.self)
            .filter { $0.hasCards }
            .compactMap { $0.date }
            .bind(with: self) { owner, date in
                let detailVC = GalleryDetailViewController(date: date)
                owner.navigationController?.pushViewController(detailVC, animated: true)
            }
            .disposed(by: disposeBag)
    }

    private func updateButtonStyles(selectedType: GalleryViewType) {
        let buttons = [dateButton, locationButton, themeButton]
        let types: [GalleryViewType] = [.date, .location, .theme]

        for (button, type) in zip(buttons, types) {
            if type == selectedType {
                button.setGradient(.blueGradient, isSelected: true)
            } else {
                button.setGradient(.grayGradient, isSelected: false)
            }
        }
    }

    private func layout() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1/7),
            heightDimension: .fractionalHeight(1)
        )

        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: /*.absolute(80)*/.fractionalWidth(1/6)
        )

        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        group.interItemSpacing = .fixed(1)

        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 1

        return UICollectionViewCompositionalLayout(section: section)
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

                    let stickerViewModel = PhotoEditorViewModel(originalImage: image)
                    let stickerVC = PhotoEditorViewController(viewModel: stickerViewModel)
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
        guard let photoAnnotation = annotation as? PhotoAnnotation else { return nil }

        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: PhotoAnnotation.identifier) as? PhotoAnnotationView

        if annotationView == nil {
            annotationView = PhotoAnnotationView(annotation: annotation, reuseIdentifier: PhotoAnnotation.identifier)
            annotationView?.clusteringIdentifier = "PhotoCluster"
        } else {
            annotationView?.annotation = annotation
        }

        if let firstPhoto = photoAnnotation.photoMemos.first,
           let image = UIImage(data: firstPhoto.editedImageData) {
            annotationView?.configure(with: image)
        }

        return annotationView
    }

    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        mapView.deselectAnnotation(view.annotation, animated: false)

        if let cluster = view.annotation as? MKClusterAnnotation {
            let photoAnnotations = cluster.memberAnnotations.compactMap { $0 as? PhotoAnnotation }
            let allPhotos = photoAnnotations.flatMap { $0.photoMemos }

            if !allPhotos.isEmpty {
                showGallery(for: allPhotos)
            }
        }
        else if let photoAnnotation = view.annotation as? PhotoAnnotation {
            showGallery(for: photoAnnotation.photoMemos)
        }
    }

    private func showGallery(for photoMemos: [Card]) {
        let galleryVC = MapPhotoGalleryViewController(photoMemos: photoMemos)
        let nav = UINavigationController(rootViewController: galleryVC)
        present(nav, animated: true)
    }
}
