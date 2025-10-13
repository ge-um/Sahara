//
//  GridLayout.swift
//  Sahara
//
//  Created by 금가경 on 10/13/25.
//

import UIKit

final class GridLayout: UICollectionViewFlowLayout {
    private let numberOfColumns: Int
    private let cellSpacing: CGFloat

    init(numberOfColumns: Int, cellSpacing: CGFloat) {
        self.numberOfColumns = numberOfColumns
        self.cellSpacing = cellSpacing
        super.init()

        self.minimumInteritemSpacing = cellSpacing
        self.minimumLineSpacing = cellSpacing
        self.sectionInset = .zero
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepare() {
        super.prepare()

        guard let collectionView = collectionView else { return }

        let availableWidth = collectionView.bounds.width - sectionInset.left - sectionInset.right
        let totalSpacing = cellSpacing * CGFloat(numberOfColumns - 1)
        let itemWidth = ((availableWidth - totalSpacing) / CGFloat(numberOfColumns)).rounded(.down)

        itemSize = CGSize(width: itemWidth, height: itemWidth)
    }
}
