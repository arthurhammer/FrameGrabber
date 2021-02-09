import Photos
import UIKit

enum LibraryGridMode: Int {
    case fit
    case square
}

extension LibraryGridMode: Hashable, Codable {}

extension LibraryGridMode {

    var toggled: LibraryGridMode {
        switch self {
        case .fit: return .square
        case .square: return .fit
        }
    }

    var title: String {
        switch self {
        case .fit: return UserText.albumViewSettingsFitGridTitle
        case .square: return UserText.albumViewSettingsSquareGridTitle
        }
    }

    var icon: UIImage? {
        if #available(iOS 14, *) {
            switch self {
            case .fit: return UIImage(systemName: "rectangle.arrowtriangle.2.inward")
            case .square: return UIImage(systemName: "rectangle.arrowtriangle.2.outward")
            }
        } else {
            switch self {
            case .fit: return UIImage(systemName: "arrow.down.right.and.arrow.up.left")
            case .square: return UIImage(systemName: "arrow.up.left.and.arrow.down.right")
            }
        }
    }

    var imageViewContentMode: UIView.ContentMode {
        switch self {
        case .fit: return .scaleAspectFit
        case .square: return .scaleAspectFill
        }
    }

    var phImageContentMode: PHImageContentMode {
        switch self {
        case .fit: return .aspectFit
        case .square: return .aspectFill
        }
    }

    func thumbnailSize(for aspectRatio: CGSize, in boundingSize: CGSize) -> CGSize {
        switch self {
        case .fit: return aspectRatio.aspectFitting(boundingSize)
        case .square: return aspectRatio.aspectFilling(boundingSize)
        }
    }
}
