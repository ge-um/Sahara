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
    private let viewTypeButtonStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 8
        return stackView
    }()

    private lazy var dateButton: UIButton = {
        let button = UIButton()
        button.setTitle("날짜별", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 8
        button.tag = 0
        return button
    }()

    private lazy var locationButton: UIButton = {
        let button = UIButton()
        button.setTitle("장소별", for: .normal)
        button.setTitleColor(.label, for: .normal)
        button.backgroundColor = .systemGray5
        button.layer.cornerRadius = 8
        button.tag = 1
        return button
    }()

    private lazy var themeButton: UIButton = {
        let button = UIButton()
        button.setTitle("주제별", for: .normal)
        button.setTitleColor(.label, for: .normal)
        button.backgroundColor = .systemGray5
        button.layer.cornerRadius = 8
        button.tag = 2
        return button
    }()
    
    private let monthNavigationView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        return view
    }()
    
    private let previousMonthButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        button.tintColor = .systemBlue
        return button
    }()
    
    private let currentMonthLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        label.textAlignment = .center
        return label
    }()
    
    private let nextMonthButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "chevron.right"), for: .normal)
        button.tintColor = .systemBlue
        return button
    }()
    
    
    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout())
        collectionView.register(GalleryCell.self, forCellWithReuseIdentifier: GalleryCell.identifier)
        collectionView.register(
            WeekdayHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: WeekdayHeaderView.identifier
        )
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
    
    init(viewModel: GalleryViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        setupMapView()
        setupThemeView()
        setupNavigationBar()
        bind()
    }

    private func setupNavigationBar() {
        let addButton = UIBarButtonItem(
            image: UIImage(systemName: "plus"),
            style: .plain,
            target: self,
            action: #selector(addButtonTapped)
        )
        navigationItem.rightBarButtonItem = addButton
    }

    @objc private func addButtonTapped() {
        var configuration = PHPickerConfiguration()
        configuration.selectionLimit = 1
        configuration.filter = .any(of: [.images])
        configuration.selection = .ordered
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
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

        // 위치가 있는 사진만 필터링
        let photoMemos = realm.objects(PhotoMemo.self)
            .filter("latitude != nil AND longitude != nil")
            .filter { $0.latitude != 0 && $0.longitude != 0 }

        // 좌표별로 그룹화
        var coordinateGroups: [String: [PhotoMemo]] = [:]
        for memo in photoMemos {
            guard let lat = memo.latitude, let lon = memo.longitude,
                  lat != 0, lon != 0 else { continue }
            let key = "\(lat),\(lon)"
            coordinateGroups[key, default: []].append(memo)
        }

        // Annotation 생성
        let annotations = coordinateGroups.compactMap { key, memos -> PhotoAnnotation? in
            guard let firstMemo = memos.first,
                  let lat = firstMemo.latitude,
                  let lon = firstMemo.longitude,
                  lat != 0, lon != 0 else { return nil }
            let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            return PhotoAnnotation(coordinate: coordinate, photoMemos: memos)
        }

        mapView.addAnnotations(annotations)

        // 모든 annotation을 보여주는 영역으로 설정
        if !annotations.isEmpty {
            mapView.showAnnotations(annotations, animated: true)
        }
    }
    
    private func configureUI() {
        view.backgroundColor = .white

        view.addSubview(viewTypeButtonStackView)
        viewTypeButtonStackView.addArrangedSubview(dateButton)
        viewTypeButtonStackView.addArrangedSubview(locationButton)
        viewTypeButtonStackView.addArrangedSubview(themeButton)

        view.addSubview(monthNavigationView)
        monthNavigationView.addSubview(previousMonthButton)
        monthNavigationView.addSubview(currentMonthLabel)
        monthNavigationView.addSubview(nextMonthButton)
        view.addSubview(collectionView)
        view.addSubview(mapView)
        view.addSubview(themeContainerView)

        viewTypeButtonStackView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(10)
            make.horizontalEdges.equalToSuperview().inset(20)
            make.height.equalTo(44)
        }
        
        monthNavigationView.snp.makeConstraints { make in
            make.top.equalTo(viewTypeButtonStackView.snp.bottom).offset(10)
            make.horizontalEdges.equalToSuperview()
            make.height.equalTo(50)
        }
        
        currentMonthLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        previousMonthButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(20)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(44)
        }
        
        nextMonthButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(20)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(44)
        }
        
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(monthNavigationView.snp.bottom)
            make.horizontalEdges.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide)
        }

        mapView.snp.makeConstraints { make in
            make.top.equalTo(monthNavigationView.snp.bottom)
            make.horizontalEdges.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide)
        }

        themeContainerView.snp.makeConstraints { make in
            make.top.equalTo(viewTypeButtonStackView.snp.bottom).offset(10)
            make.horizontalEdges.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide)
        }
    }
    
    private func bind() {
        let dateButtonTap = dateButton.rx.tap.map { GalleryViewType.date }
        let locationButtonTap = locationButton.rx.tap.map { GalleryViewType.location }
        let themeButtonTap = themeButton.rx.tap.map { GalleryViewType.theme }

        let viewTypeSelected = Observable.merge(dateButtonTap, locationButtonTap, themeButtonTap)
            .startWith(.date)

        viewTypeSelected
            .bind(with: self) { owner, viewType in
                owner.updateButtonStyles(selectedType: viewType)
            }
            .disposed(by: disposeBag)

        let input = GalleryViewModel.Input(
            viewWillAppear: rx.methodInvoked(#selector(viewWillAppear)).map { _ in },
            addButtonTapped: Observable.never(),
            previousMonthTapped: previousMonthButton.rx.tap.asObservable(),
            nextMonthTapped: nextMonthButton.rx.tap.asObservable(),
            viewTypeSelected: viewTypeSelected
        )

        let output = viewModel.transform(input: input)
        
        let dataSource = RxCollectionViewSectionedReloadDataSource<CalendarSection>(
            configureCell: { _, collectionView, indexPath, item in
                guard let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: GalleryCell.identifier,
                    for: indexPath
                ) as? GalleryCell else {
                    return UICollectionViewCell()
                }
                cell.configure(with: item)
                return cell
            },
            configureSupplementaryView: { _, collectionView, kind, indexPath in
                guard let header = collectionView.dequeueReusableSupplementaryView(
                    ofKind: kind,
                    withReuseIdentifier: WeekdayHeaderView.identifier,
                    for: indexPath
                ) as? WeekdayHeaderView else {
                    return UICollectionReusableView()
                }
                return header
            }
        )
        
        output.calendarItems
            .map { [CalendarSection(items: $0)] }
            .drive(collectionView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
        
        output.currentMonthTitle
            .drive(currentMonthLabel.rx.text)
            .disposed(by: disposeBag)
        
        output.selectedViewType
            .drive(with: self) { owner, viewType in
                owner.monthNavigationView.isHidden = viewType != .date
                owner.collectionView.isHidden = viewType != .date
                owner.mapView.isHidden = viewType != .location
                owner.themeContainerView.isHidden = viewType != .theme

                if viewType == .location {
                    owner.loadMapAnnotations()
                } else if viewType == .theme {
                    owner.themeGalleryVC.viewWillAppear(false)
                }
            }
            .disposed(by: disposeBag)

        // 뷰가 나타날 때마다 location 뷰도 갱신
        rx.methodInvoked(#selector(viewWillAppear))
            .withLatestFrom(output.selectedViewType.asObservable())
            .filter { $0 == .location }
            .bind(with: self) { owner, _ in
                owner.loadMapAnnotations()
            }
            .disposed(by: disposeBag)
        
        collectionView.rx.modelSelected(DayItem.self)
            .filter { $0.hasPhotos } // 사진이 있는 날짜만 필터링
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
                button.backgroundColor = .systemBlue
                button.setTitleColor(.white, for: .normal)
            } else {
                button.backgroundColor = .systemGray5
                button.setTitleColor(.label, for: .normal)
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
            heightDimension: .fractionalHeight(1/7)
        )

        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

        let headerSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .absolute(40)
        )

        let header = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: headerSize,
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top
        )

        let section = NSCollectionLayoutSection(group: group)
        section.boundarySupplementaryItems = [header]

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

                    // 사진 선택 후 바로 스티커 편집 화면으로 이동
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

        let identifier = "PhotoAnnotation"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView

        if annotationView == nil {
            annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            annotationView?.canShowCallout = true
            annotationView?.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            annotationView?.clusteringIdentifier = "PhotoCluster"
        } else {
            annotationView?.annotation = annotation
        }

        // 첫 번째 사진을 핀에 표시
        if let firstPhoto = photoAnnotation.photoMemos.first,
           let image = UIImage(data: firstPhoto.imageData) {
            let size = CGSize(width: 40, height: 40)
            UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
            image.draw(in: CGRect(origin: .zero, size: size))
            let thumbnailImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()

            annotationView?.image = thumbnailImage
            annotationView?.layer.cornerRadius = 20
        } else {
            annotationView?.markerTintColor = .systemBlue
            annotationView?.glyphText = "\(photoAnnotation.photoMemos.count)"
        }

        return annotationView
    }

    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        guard let photoAnnotation = view.annotation as? PhotoAnnotation else { return }
        showGallery(for: photoAnnotation.photoMemos)
    }

    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        // 클러스터를 탭하면 자동으로 확대되지만, 추가로 갤러리를 보여줄 수도 있습니다
        if let cluster = view.annotation as? MKClusterAnnotation {
            let photoAnnotations = cluster.memberAnnotations.compactMap { $0 as? PhotoAnnotation }
            let allPhotos = photoAnnotations.flatMap { $0.photoMemos }

            if !allPhotos.isEmpty {
                // 클러스터 내 모든 사진 보여주기
                showGallery(for: allPhotos)
            }
        }
    }

    private func showGallery(for photoMemos: [PhotoMemo]) {
        let galleryVC = MapPhotoGalleryViewController(photoMemos: photoMemos)
        let nav = UINavigationController(rootViewController: galleryVC)
        present(nav, animated: true)
    }
}
