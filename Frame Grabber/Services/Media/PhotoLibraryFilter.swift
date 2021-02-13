import Photos
import UIKit

enum PhotoLibraryFilter: Int {
    case videoAndLivePhoto
    case video
    case livePhoto
}

extension PhotoLibraryFilter: CaseIterable, Hashable, Codable {}

extension PhotoLibraryFilter {

    var title: String {
        switch self {
        case .videoAndLivePhoto: return UserText.videoFilterAllItems
        case .video: return UserText.videoFilterVideos
        case .livePhoto: return UserText.videoFilterLivePhotos
        }
    }

    var icon: UIImage? {
        switch self {
        case .videoAndLivePhoto: return UIImage(systemName: "square.grid.2x2")
        case .video: return  UIImage(systemName: "video")
        case .livePhoto: return  UIImage(systemName: "livephoto")
        }
    }

    var photoLibraryFetchPredicate: NSPredicate {
        switch self  {

        case .videoAndLivePhoto:
            return NSCompoundPredicate(orPredicateWithSubpredicates: [
                PhotoLibraryFilter.video.photoLibraryFetchPredicate,
                PhotoLibraryFilter.livePhoto.photoLibraryFetchPredicate
            ])

        case .video:
            return NSPredicate(format: "(mediaType == %d)", PHAssetMediaType.video.rawValue)

        case .livePhoto:
            return NSPredicate(format: "(mediaSubtypes & %d) != 0", PHAssetMediaSubtype.photoLive.rawValue)
        }
    }
}
