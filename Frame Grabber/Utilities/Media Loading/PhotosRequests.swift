import Photos

extension PHAsset {
    static func fetchVideos(with options: PHFetchOptions? = .default()) -> PHFetchResult<PHAsset> {
        return PHAsset.fetchAssets(with: .video, options: options)
    }
}

extension PHFetchOptions {
    static func `default`() -> PHFetchOptions {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.includeAssetSourceTypes = [.typeUserLibrary, .typeiTunesSynced, .typeCloudShared]
        return fetchOptions
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
