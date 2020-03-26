import Photos

extension PHFetchOptions {

    static func userAlbums() -> PHFetchOptions {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "localizedTitle", ascending: true)]
        return options
    }

    static func assets(forAlbumType albumType: PHAssetCollectionType, videoType: VideoType) -> PHFetchOptions {
        let options = PHFetchOptions()
        options.predicate = videoType.fetchPredicate
        options.sortDescriptors = albumType.sortDescriptors
        options.includeAssetSourceTypes = [.typeUserLibrary, .typeiTunesSynced, .typeCloudShared]
        return options
    }
}

extension PHAssetCollectionType {

    var sortDescriptors: [NSSortDescriptor]? {
        switch self {
        case .smartAlbum: return [NSSortDescriptor(key: "creationDate", ascending: false)]
        case .album: return nil
        default: return nil
        }
    }
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
