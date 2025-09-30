//
//  GalleryViewController.swift
//  Sahara
//
//  Created by 금가경 on 9/26/25.
//

import PhotosUI
import RxCocoa
import RxSwift
import RxDataSources
import SnapKit
import UIKit

final class GalleryViewController: UIViewController {
    private let addButton: UIButton = {
        let button = UIButton()
        var config = UIButton.Configuration.plain()
        config.title = "메모 작성하기"
        config.baseForegroundColor = .white
        config.background.backgroundColor = .systemBlue
        button.configuration = config
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
        bind()
    }
    
    private func configureUI() {
        view.backgroundColor = .white
        
        view.addSubview(addButton)
        view.addSubview(collectionView)

        addButton.snp.makeConstraints { make in
            make.bottom.equalToSuperview().inset(20)
            make.centerX.equalToSuperview()
            make.height.equalTo(44)
        }
        
        collectionView.snp.makeConstraints { make in
            make.top.horizontalEdges.equalToSuperview()
            make.bottom.equalTo(addButton.snp.top)
        }
    }

    private func bind() {
        let input = GalleryViewModel.Input(
            viewWillAppear: rx.methodInvoked(#selector(viewWillAppear)).map { _ in },
            addButtonTapped: addButton.rx.tap.asObservable()
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
        
        collectionView.rx.modelSelected(DayItem.self)
            .compactMap { $0.date }
            .bind(with: self) { owner, date in
                let detailVC = GalleryDetailViewController(date: date)
                owner.navigationController?.pushViewController(detailVC, animated: true)
            }
            .disposed(by: disposeBag)
        
        output.showPhotoPicker
            .drive(with: self) { owner, _ in
                var configuration = PHPickerConfiguration()
                configuration.selectionLimit = 1
                configuration.filter = .any(of: [.images])
                let picker = PHPickerViewController(configuration: configuration)
                picker.delegate = self
                owner.present(picker, animated: true)
            }
            .disposed(by: disposeBag)
    }
    
    private func layout() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1/7),
            heightDimension: .fractionalHeight(1)
        )
        
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .fractionalHeight(1/5)
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
        
        let itemProvider = results.first?.itemProvider
        
        if let itemProvider = itemProvider, itemProvider.canLoadObject(ofClass: UIImage.self) {
            itemProvider.loadObject(ofClass: UIImage.self) { image, error in
                DispatchQueue.main.async {
                    let image = image as? UIImage
                    
                    let vm = EditPhotoViewModel(selectedPhoto: image)
                    let vc = UINavigationController(rootViewController: EditPhotoViewController(viewModel: vm))
                    vc.modalPresentationStyle = .fullScreen
                    self.present(vc, animated: true)
                }
            }
        }
    }
}
