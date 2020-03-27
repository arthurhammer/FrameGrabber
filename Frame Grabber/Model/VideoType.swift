import Photos

enum VideoType: Int, Codable {
    case any
    case video
    case livePhoto
}

extension VideoType {

    var fetchPredicate: NSPredicate {
        switch self  {
        case .any: return NSPredicate(format: "(mediaType == %d) OR (mediaSubtypes & %d) != 0", PHAssetMediaType.video.rawValue, PHAssetMediaSubtype.photoLive.rawValue)
        case .video: return NSPredicate(format: "(mediaType == %d)", PHAssetMediaType.video.rawValue)
        case .livePhoto: return NSPredicate(format: "(mediaSubtypes & %d) != 0", PHAssetMediaSubtype.photoLive.rawValue)
        }
    }
}
