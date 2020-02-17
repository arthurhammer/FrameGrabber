import Photos

extension PHAssetCollection {

    static func fetchSmartAlbums(with types: [PHAssetCollectionSubtype]) -> [PHAssetCollection] {
        let options = PHFetchOptions()
        options.fetchLimit = 1

        return types.compactMap {
            fetchAssetCollections(with: .smartAlbum, subtype: $0, options: options).firstObject
        }
    }

    static func fetchUserAlbums(with options: PHFetchOptions? = nil) -> PHFetchResult<PHAssetCollection> {
        fetchAssetCollections(with: .album, subtype: .albumRegular, options: options)
    }
}

extension PHFetchOptions {

    static func userAlbums() -> PHFetchOptions {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "localizedTitle", ascending: true)]
        return options
    }

    /// Smart albums are naturally unordered, sort by date.
    static func smartAlbumVideos(containing type: VideoType) -> PHFetchOptions {
        let options = PHFetchOptions()
        options.predicate = type.fetchPredicate
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        options.includeAssetSourceTypes = [.typeUserLibrary, .typeiTunesSynced, .typeCloudShared]
        return options
    }

    /// Default user-defined order.
    static func userAlbumVideos(containing type: VideoType) -> PHFetchOptions {
        let options = PHFetchOptions()
        options.predicate = type.fetchPredicate
        options.includeAssetSourceTypes = [.typeUserLibrary, .typeiTunesSynced, .typeCloudShared]
        return options
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
