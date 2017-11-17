import Photos

extension PHPhotoLibrary {

    /// Request authorization optionally opening settings if status is denied or restricted.
    static func requestAuthorization(openingSettingsIfNecessary openSettings: Bool, completion: @escaping (PHAuthorizationStatus, Bool) -> ()) {
        let status = authorizationStatus()
        let isDenied = (status == .denied || status == .restricted)

        // Go to settings if denied
        if isDenied && openSettings {
            UIApplication.shared.openSettings() { didOpen in
                completion(status, didOpen)
            }
            return
        }

        // Request authorization otherwise
        PHPhotoLibrary.requestAuthorization { status in
            DispatchQueue.main.async {
                completion(status, false)
            }
        }
    }

    static var isAuthorized: Bool {
        return authorizationStatus() == .authorized
    }
}

extension PHPhotoLibraryChangeObserver {

    func startObservingPhotoLibrary() {
        PHPhotoLibrary.shared().register(self)
    }

    func stopObservingPhotoLibrary() {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }
}


extension PHFetchResult  {
    @objc var isEmpty: Bool {
        return count == 0
    }
}

extension PHAsset {
    var pixelSize: CGSize {
        return CGSize(width: pixelWidth, height: pixelHeight)
    }
}

// MARK: - App-specific Default Options

extension PHAsset {
    static func videos(with options: PHFetchOptions? = .video()) -> PHFetchResult<PHAsset> {
        return PHAsset.fetchAssets(with: .video, options: options)
    }
}

extension PHFetchOptions {
    static func appDefault() -> PHFetchOptions {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.includeAssetSourceTypes = [.typeUserLibrary, .typeiTunesSynced, .typeCloudShared]
        return fetchOptions
    }

    static var video = appDefault
}

extension PHImageRequestOptions {
    static func appDefault() -> PHImageRequestOptions {
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .opportunistic
        return options
    }

    static var videoPreview = appDefault
    static var videoLibraryThumbnail = appDefault
}

extension PHVideoRequestOptions {
    static func appDefault() -> PHVideoRequestOptions {
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat
        return options
    }

    static var video = appDefault
}
