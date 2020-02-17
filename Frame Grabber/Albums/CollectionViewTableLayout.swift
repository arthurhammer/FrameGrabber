import UIKit

class CollectionViewTableLayout: UICollectionViewFlowLayout {

    let itemHeight: CGFloat

    init(itemHeight: CGFloat = 80, lineSpacing: CGFloat = 0, sectionInset: UIEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 30, right: 0)) {
        self.itemHeight = itemHeight
        super.init()
        self.sectionInsetReference = .fromSafeArea
        self.minimumLineSpacing = lineSpacing
        self.sectionInset = sectionInset
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
