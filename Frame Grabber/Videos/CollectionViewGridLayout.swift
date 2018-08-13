import UIKit

class CollectionViewGridLayout: UICollectionViewFlowLayout {

    let preferredItemSize: CGFloat
    let minimumItemsPerRow: Int
    let itemSpacing: CGFloat

    init(preferredItemSize: CGFloat = 100, minimumItemsPerRow: Int = 3, itemSpacing: CGFloat = 1) {
        self.preferredItemSize = preferredItemSize
        self.minimumItemsPerRow = minimumItemsPerRow
        self.itemSpacing = itemSpacing

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateItemSize(forBoundingSize size: CGSize) {
        let fullWidth = size.width
        let minimumItemsPerRow = CGFloat(self.minimumItemsPerRow)

        let itemsPerRow = max(floor(fullWidth / preferredItemSize), minimumItemsPerRow)
        let itemWidth = floor((fullWidth - (itemsPerRow - 1) * itemSpacing) / itemsPerRow)
        let itemSize = CGSize(width: itemWidth, height: itemWidth)

        self.itemSize = itemSize
        self.minimumLineSpacing = itemSpacing
        self.minimumInteritemSpacing = itemSpacing
    }
}
