import UIKit

class LibraryGridLayout: UICollectionViewCompositionalLayout {

    init(
        preferredItemSize: CGFloat = 160,
        minimumItemsPerCompactRow: Int = 3,
        minimumItemsPerRegularRow: Int = 5,
        preferredSpacing: CGFloat = 2
    ) {
        let configuration = UICollectionViewCompositionalLayoutConfiguration()
        
        configuration.contentInsetsReference = .none
        
        super.init(sectionProvider: { _, environment in
            // We can't use the regular horizontal class since smaller phones still are horizontally
            // compact in landscape. Use the compact vertical class as an indicator for landscape.
            let minItemsPerRow = (environment.traitCollection.verticalSizeClass == .compact)
                ? minimumItemsPerRegularRow
                : minimumItemsPerCompactRow

            let width = environment.container.effectiveContentSize.width
            
            let itemsPerRow = max(CGFloat(minItemsPerRow), floor(width / preferredItemSize))
            let itemWidth = floor((width - (itemsPerRow-1)*preferredSpacing) / itemsPerRow)
            let remainingSpacing = (width - itemsPerRow*itemWidth) / (itemsPerRow-1)

            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalHeight(1), heightDimension: .fractionalHeight(1))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)

            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(itemWidth))
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
            group.interItemSpacing = .fixed(remainingSpacing)
            
            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = remainingSpacing

            return section
        }, configuration: configuration)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
