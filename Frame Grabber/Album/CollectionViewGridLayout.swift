import UIKit

class CollectionViewGridLayout: UICollectionViewFlowLayout {

    let preferredItemSize: CGFloat
    let minimumItemsPerRow: Int

    init(preferredItemSize: CGFloat = 100, minimumItemsPerRow: Int = 3, itemSpacing: CGFloat = 1) {
        self.preferredItemSize = preferredItemSize
        self.minimumItemsPerRow = minimumItemsPerRow

        super.init()

        self.minimumLineSpacing = itemSpacing
        self.minimumInteritemSpacing = itemSpacing
        self.sectionInsetReference = .fromSafeArea
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepare() {
        super.prepare()
        collectionView?.contentInsetAdjustmentBehavior = .always
        updateItemSize(for: collectionViewContentSize)
    }

    func updateItemSize(for boundingSize: CGSize) {
        let width = boundingSize.width

        let itemsPerRow = max(floor(width / preferredItemSize), CGFloat(minimumItemsPerRow))
        let itemWidth = floor((width - (itemsPerRow - 1) * minimumInteritemSpacing) / itemsPerRow)

        let newSize = CGSize(width: max(0, itemWidth), height: max(0, itemWidth))

        if newSize != itemSize {
            itemSize = newSize
        }
    }
}
