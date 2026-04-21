//
//  CalendarLayout.swift
//  Sahara
//
//  Created by 금가경 on 3/16/26.
//

import UIKit

final class CalendarLayout: UICollectionViewFlowLayout {
    override init() {
        super.init()
        minimumInteritemSpacing = 1
        minimumLineSpacing = 1
        sectionInset = .zero
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepare() {
        super.prepare()
        guard let collectionView = collectionView else { return }

        let headerHeight: CGFloat = 72
        headerReferenceSize = CGSize(width: collectionView.bounds.width, height: headerHeight)

        let width = collectionView.bounds.width
        let itemWidth = ((width - 6) / 7).rounded(.down)
        let height = collectionView.bounds.height - headerHeight
        let itemHeight = ((height - 5) / 6).rounded(.down)

        itemSize = CGSize(width: itemWidth, height: itemHeight)
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        guard let collectionView = collectionView else { return false }
        return newBounds.size != collectionView.bounds.size
    }
}
