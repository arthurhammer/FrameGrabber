import UIKit

class CollectionViewGridLayout: UICollectionViewFlowLayout {

    let preferredItemWidth: CGFloat
    let minimumItemsPerRow: Int
    let itemSpacing: CGFloat

    init(preferredItemWidth: CGFloat = 100, minimumItemsPerRow: Int = 3, itemSpacing: CGFloat = 2) {
        self.preferredItemWidth = preferredItemWidth
        self.minimumItemsPerRow = minimumItemsPerRow
        self.itemSpacing = itemSpacing

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Update `itemSize` to fit into the collection view's width.
    /// Has no effect if the layout is not assigned to a collection view.
    func updateItemSize() {
        guard let fullWidth = collectionView?.bounds.width else { return }

        let minimumItemsPerRow = CGFloat(self.minimumItemsPerRow)

        let itemsPerRow = max(floor(fullWidth / preferredItemWidth), minimumItemsPerRow)
        let itemWidth = floor((fullWidth - (itemsPerRow - 1) * itemSpacing) / itemsPerRow)
        let itemSize = CGSize(width: itemWidth, height: itemWidth)

        self.itemSize = itemSize
        self.minimumLineSpacing = itemSpacing
        self.minimumInteritemSpacing = itemSpacing
    }
}
