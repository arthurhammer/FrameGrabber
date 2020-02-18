import Photos

protocol PhotosIdentifiable {
    var id: String { get }
}

protocol Album: PhotosIdentifiable {
    var assetCollection: PHAssetCollection { get }
    var title: String? { get }
    var count: Int { get }
    var keyAsset: PHAsset? { get }
}

extension Album {
    var id: String {
        assetCollection.localIdentifier
    }

    var title: String? {
        assetCollection.localizedTitle
    }

    var isEmpty: Bool {
        count == 0
    }
}

// MARK: -

import UIKit

extension Album {

    var icon: UIImage? {
        switch assetCollection.assetCollectionSubtype {
        case .smartAlbumUserLibrary: return UIImage(systemName: "camera")
        case .smartAlbumFavorites: return UIImage(systemName: "heart")
        case .smartAlbumTimelapses: return UIImage(systemName: "timelapse")
        case .smartAlbumSlomoVideos: return UIImage(systemName: "slowmo")
        default: return UIImage(systemName: "photo.on.rectangle")
        }
    }
}
