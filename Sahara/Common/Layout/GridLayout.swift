//
//  GridLayout.swift
//  Sahara
//
//  Created by 금가경 on 10/13/25.
//

import UIKit

final class GridLayout: UICollectionViewFlowLayout {
    private(set) var numberOfColumns: Int
    private let cellSpacing: CGFloat
    private let minColumnWidth: CGFloat?

    init(numberOfColumns: Int, cellSpacing: CGFloat, minColumnWidth: CGFloat? = nil) {
        self.numberOfColumns = numberOfColumns
        self.cellSpacing = cellSpacing
        self.minColumnWidth = minColumnWidth
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

        if let minColumnWidth = minColumnWidth {
            numberOfColumns = max(2, Int(availableWidth / minColumnWidth))
        }

        let totalSpacing = cellSpacing * CGFloat(numberOfColumns - 1)
        let itemWidth = ((availableWidth - totalSpacing) / CGFloat(numberOfColumns)).rounded(.down)

        itemSize = CGSize(width: itemWidth, height: itemWidth)
    }
}
