import UIKit

extension CGSize {
    // The receiver scaled with the screen's scale.
    var scaledToScreen: CGSize {
        let scale = UIScreen.main.scale
        return CGSize(width: width * scale, height: height * scale)
    }
}

extension UICollectionView {
    func clearSelection() {
        selectItem(at: nil, animated: true, scrollPosition: .top)
    }
}
