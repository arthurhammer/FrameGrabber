import Photos
import UIKit

enum VideoTypesFilter: Int {
    case all
    case video
    case livePhoto
}

extension VideoTypesFilter: CaseIterable, Hashable, Codable {}

extension VideoTypesFilter {

    var title: String {
        switch self {
        case .all: return UserText.videoFilterAllItems
        case .video: return UserText.videoFilterVideos
        case .livePhoto: return UserText.videoFilterLivePhotos
        }
    }

    var icon: UIImage? {
        switch self {
        case .all: return UIImage(systemName: "square.grid.2x2")
        case .video: return  UIImage(systemName: "video")
        case .livePhoto: return  UIImage(systemName: "livephoto")
        }
    }

    var photoLibraryFetchPredicate: NSPredicate {
        switch self  {

        case .all:
            return NSCompoundPredicate(orPredicateWithSubpredicates: [
                VideoTypesFilter.video.photoLibraryFetchPredicate,
                VideoTypesFilter.livePhoto.photoLibraryFetchPredicate
            ])

        case .video:
            return NSPredicate(format: "(mediaType == %d)", PHAssetMediaType.video.rawValue)

        case .livePhoto:
            return NSPredicate(format: "(mediaSubtypes & %d) != 0", PHAssetMediaSubtype.photoLive.rawValue)
        }
    }
}
