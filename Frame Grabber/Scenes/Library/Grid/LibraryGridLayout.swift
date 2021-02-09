import UIKit

class LibraryGridLayout: UICollectionViewCompositionalLayout {

    init(preferredItemSize: CGFloat = 120, minimumItemsPerRow: Int = 3, spacing: CGFloat = 2, didUpdateItemSizeHandler: ((CGSize) -> ())? = nil) {
        super.init { _, environment in
            let width = environment.container.effectiveContentSize.width
            let itemsPerRow = max(CGFloat(minimumItemsPerRow), floor(width / preferredItemSize))
            let itemWidth = floor((width - (itemsPerRow-1)*spacing) / itemsPerRow)
            let remainingSpacing = (width - itemsPerRow*itemWidth) / (itemsPerRow-1)

            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalHeight(1), heightDimension: .fractionalHeight(1))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)

            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(itemWidth))
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
            group.interItemSpacing = .fixed(remainingSpacing)
            
            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = remainingSpacing

            didUpdateItemSizeHandler?(CGSize(width: itemWidth, height: itemWidth))
            return section
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
