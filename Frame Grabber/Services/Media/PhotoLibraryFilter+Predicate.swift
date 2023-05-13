import Foundation
import Photos

extension PhotoLibraryFilter {

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
