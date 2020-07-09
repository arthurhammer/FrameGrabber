import Photos

enum VideoTypesFilter: Int {
    case all
    case video
    case livePhoto
}

extension VideoTypesFilter: CaseIterable, Hashable, Codable {}

extension VideoTypesFilter {

    var fetchPredicate: NSPredicate {
        switch self  {

        case .all:
            return NSPredicate(
                format: "(mediaType == %d) OR (mediaSubtypes & %d) != 0",
                PHAssetMediaType.video.rawValue,
                PHAssetMediaSubtype.photoLive.rawValue
            )

        case .video:
            return NSPredicate(format: "(mediaType == %d)", PHAssetMediaType.video.rawValue)

        case .livePhoto:
            return NSPredicate(format: "(mediaSubtypes & %d) != 0", PHAssetMediaSubtype.photoLive.rawValue)
        }
    }
}
