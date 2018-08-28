import UIKit

class CollectionViewTableLayout: UICollectionViewFlowLayout {

    let itemHeight: CGFloat

    init(itemHeight: CGFloat = 90, lineSpacing: CGFloat = 0) {
        self.itemHeight = itemHeight
        super.init()
        self.sectionInsetReference = .fromSafeArea
        self.minimumLineSpacing = lineSpacing
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
        let newSize = CGSize(width: boundingSize.width, height: itemHeight)

        if newSize != itemSize {
            itemSize = newSize
        }
    }
}
