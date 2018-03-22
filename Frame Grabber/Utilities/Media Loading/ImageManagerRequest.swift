import Photos

/// Base class for a `PHImageManager` request that automatically cancels on `deinit`.
class ImageManagerRequest {

    /// Wrapper around the result handler info dictionary
    struct Info {
        let info: [AnyHashable: Any]
    }

    fileprivate let imageManager: PHImageManager
    fileprivate var id: PHImageRequestID?

    fileprivate init(imageManager: PHImageManager) {
        self.imageManager = imageManager
    }

    deinit {
        cancel()
    }

    func cancel() {
        guard let id = id else { return }
        imageManager.cancelImageRequest(id)
        self.id = nil
    }
}

class ImageRequest: ImageManagerRequest {

    var image: UIImage?

    /// The handler is called asynchronously on the main thread.
    /// - Note: The result handler may be called multiple times, depending on `options`.
    init(imageManager: PHImageManager, asset: PHAsset, targetSize: CGSize, contentMode: PHImageContentMode, options: PHImageRequestOptions?, resultHandler: @escaping (UIImage?, Info) -> ()) {
        super.init(imageManager: imageManager)

        id = imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: contentMode, options: options) { [weak self] image, info in
            DispatchQueue.main.async {
                self?.image = image
                resultHandler(image, Info(info: info))
            }
        }
    }
}

class PlayerItemRequest: ImageManagerRequest {

    var playerItem: AVPlayerItem?

    /// The handler is called asynchronously on the main thread
    init(imageManager: PHImageManager, video: PHAsset, options: PHVideoRequestOptions?, resultHandler: @escaping (AVPlayerItem?, Info) -> ()) {
        super.init(imageManager: imageManager)

        id = imageManager.requestPlayerItem(forVideo: video, options: options) { [weak self] playerItem, info in
            DispatchQueue.main.async {
                self?.playerItem = playerItem
                resultHandler(playerItem, Info(info: info))
            }
        }
    }
}

class AVAssetRequest: ImageManagerRequest {

    var avAsset: AVAsset?

    /// The handler is called asynchronously on the main thread.
    /// If a progress handler is provided, it overrides the one in `options`.
    init(imageManager: PHImageManager, video: PHAsset, options: PHVideoRequestOptions?, progressHandler: ((Double) -> ())? = nil, resultHandler: @escaping (AVAsset?, AVAudioMix?, Info) -> ()) {
        super.init(imageManager: imageManager)

        let options = options ?? PHVideoRequestOptions()

        if let progressHandler = progressHandler {
            options.progressHandler = { progress, error, stop, info in
                progressHandler(progress)
            }
        }

        id = imageManager.requestAVAsset(forVideo: video, options: options) { [weak self] asset, mix, info in
            DispatchQueue.main.async {
                self?.avAsset = asset
                resultHandler(asset, mix, Info(info: info))
            }
        }
    }
}

// MARK: - Info

extension ImageManagerRequest.Info {

    init(info: [AnyHashable: Any]?) {
        self.init(info: info ?? [:])
    }

    var error: Error? {
        return info[PHImageErrorKey] as? Error
    }

    var isCancelled: Bool {
        return (info[PHImageCancelledKey] as? Bool) ?? false
    }

    var isDegraded: Bool {
        return (info[PHImageResultIsDegradedKey] as? Bool) ?? false
    }

    var isInCloud: Bool {
        return (info[PHImageResultIsInCloudKey] as? Bool) ?? false
    }

    var requestId: Int? {
        return info[PHImageResultRequestIDKey] as? Int
    }
}
