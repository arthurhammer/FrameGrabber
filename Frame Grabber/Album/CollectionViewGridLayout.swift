import UIKit

class CollectionViewGridLayout: UICollectionViewFlowLayout {

    let preferredItemSize: CGFloat
    let preferredSpacing: CGFloat
    let minimumItemsPerRow: Int

    init(preferredItemSize: CGFloat = 120, minimumItemsPerRow: Int = 3, preferredSpacing: CGFloat = 1) {
        self.preferredItemSize = preferredItemSize
        self.preferredSpacing = preferredSpacing
        self.minimumItemsPerRow = minimumItemsPerRow

        super.init()

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
        let itemWidth = floor((width - (itemsPerRow - 1) * preferredSpacing) / itemsPerRow)

        let newSize = CGSize(width: max(0, itemWidth), height: max(0, itemWidth))
        let newSpacing = (width - (itemsPerRow) * itemWidth) / (itemsPerRow - 1)

        if newSize != itemSize {
            itemSize = newSize
            minimumLineSpacing = newSpacing
            minimumInteritemSpacing = newSpacing
        }
    }
}
