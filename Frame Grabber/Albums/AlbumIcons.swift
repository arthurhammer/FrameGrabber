import UIKit

extension Album {

    var icon: UIImage? {
        UIImage(systemName: iconName)
    }

    private var iconName: String {
        switch assetCollection.assetCollectionSubtype {
        case .smartAlbumUserLibrary: return "camera"
        case .smartAlbumFavorites: return "heart"
        case .smartAlbumTimelapses: return "timelapse"
        case .smartAlbumSlomoVideos: return "slowmo"
        default: return "photo.on.rectangle"
        }
    }
}
