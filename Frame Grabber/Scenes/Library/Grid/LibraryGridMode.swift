import Photos
import Utility
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
        case .fit: return Localized.albumViewSettingsFitGridTitle
        case .square: return Localized.albumViewSettingsSquareGridTitle
        }
    }

    var icon: UIImage? {
        switch self {
        case .fit: return UIImage(systemName: "rectangle.arrowtriangle.2.inward")
        case .square: return UIImage(systemName: "rectangle.arrowtriangle.2.outward")
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
