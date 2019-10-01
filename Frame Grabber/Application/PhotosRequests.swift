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
    /// Smart albums are naturally unordered, sort by date.
    static func smartAlbumVideos() -> PHFetchOptions {
        let options = PHFetchOptions()
        options.predicate = NSPredicate(mediaType: .video)
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        options.includeAssetSourceTypes = [.typeUserLibrary, .typeiTunesSynced, .typeCloudShared]
        return options
    }

    /// For user albums use default user-defined order.
    static func userAlbumVideos() -> PHFetchOptions {
        let options = PHFetchOptions()
        options.predicate = NSPredicate(mediaType: .video)
        options.includeAssetSourceTypes = [.typeUserLibrary, .typeiTunesSynced, .typeCloudShared]
        return options
    }

    static func userAlbums() -> PHFetchOptions {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "localizedTitle", ascending: true)]
        return options
    }
}

extension NSPredicate {
    convenience init(mediaType: PHAssetMediaType) {
        self.init(format: "mediaType == %d", mediaType.rawValue)
    }
}

extension PHImageRequestOptions {
    static func `default`() -> PHImageRequestOptions {
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .opportunistic
        return options
    }
}

extension PHVideoRequestOptions {
    static func `default`() -> PHVideoRequestOptions {
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat
        return options
    }
}
