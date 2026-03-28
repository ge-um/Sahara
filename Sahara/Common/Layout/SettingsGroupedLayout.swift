//
//  SettingsGroupedLayout.swift
//  Sahara
//
//  Created by 금가경 on 3/27/26.
//

import UIKit

final class SettingsGroupedLayout: UICollectionViewFlowLayout {
    private var decorationAttributes: [UICollectionViewLayoutAttributes] = []

    override init() {
        super.init()
        minimumLineSpacing = 0
        minimumInteritemSpacing = 0
        sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 24, right: 0)
        register(
            SettingsSectionBackgroundView.self,
            forDecorationViewOfKind: SettingsSectionBackgroundView.elementKind
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepare() {
        super.prepare()
        decorationAttributes.removeAll()

        guard let collectionView = collectionView else { return }
        let numberOfSections = collectionView.numberOfSections

        for section in 0..<numberOfSections {
            let numberOfItems = collectionView.numberOfItems(inSection: section)
            guard numberOfItems > 0 else { continue }

            let firstIndexPath = IndexPath(item: 0, section: section)
            let lastIndexPath = IndexPath(item: numberOfItems - 1, section: section)

            guard
                let firstAttributes = layoutAttributesForItem(at: firstIndexPath),
                let lastAttributes = layoutAttributesForItem(at: lastIndexPath)
            else { continue }

            let sectionFrame = firstAttributes.frame.union(lastAttributes.frame)

            let attributes = UICollectionViewLayoutAttributes(
                forDecorationViewOfKind: SettingsSectionBackgroundView.elementKind,
                with: IndexPath(item: 0, section: section)
            )
            attributes.frame = sectionFrame
            attributes.zIndex = -1

            decorationAttributes.append(attributes)
        }
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var allAttributes = super.layoutAttributesForElements(in: rect) ?? []
        for attributes in decorationAttributes where rect.intersects(attributes.frame) {
            allAttributes.append(attributes)
        }
        return allAttributes
    }

    override func layoutAttributesForDecorationView(
        ofKind elementKind: String,
        at indexPath: IndexPath
    ) -> UICollectionViewLayoutAttributes? {
        decorationAttributes.first { $0.indexPath == indexPath }
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        guard let collectionView = collectionView else { return false }
        return newBounds.size != collectionView.bounds.size
    }
}
