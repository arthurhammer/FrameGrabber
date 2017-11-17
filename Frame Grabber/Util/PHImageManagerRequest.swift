import Photos

/// Base class for a `PHImageManager` request that automatically cancels on `deinit`.
class PHImageManagerRequest {
    private let manager: PHImageManager
    fileprivate var id: PHImageRequestID?

    fileprivate init(manager: PHImageManager = .default()) {
        self.manager = manager
    }

    deinit {
        cancel()
    }

    func cancel() {
        guard let id = id else { return }
        manager.cancelImageRequest(id)
    }
}

class ImageRequest: PHImageManagerRequest {
    var image: UIImage?

    init(manager: PHImageManager = .default(), asset: PHAsset, targetSize: CGSize, contentMode: PHImageContentMode, options: PHImageRequestOptions?, resultHandler: @escaping (UIImage?, [AnyHashable: Any]?) -> ()) {
        super.init(manager: manager)

        id = manager.requestImage(for: asset, targetSize: targetSize, contentMode: contentMode, options: options) { [weak self] image, info in
            DispatchQueue.main.async {
                guard let this = self else { return }

                // When delivery mode is `opportunistic` a degraded image might be provided
                // first but a subsequent high-quality image might fail. Don't report the
                // second image if the first image succeeded but the second didn't.
                guard this.image == nil || image != nil else { return }

                this.image = image
                resultHandler(image, info)
            }
        }
    }
}

class PlayerItemRequest: PHImageManagerRequest {
    var playerItem: AVPlayerItem?

    init(manager: PHImageManager = .default(), video: PHAsset, options: PHVideoRequestOptions?, resultHandler: @escaping (AVPlayerItem?, [AnyHashable: Any]?) -> ()) {
        super.init(manager: manager)

        id = manager.requestPlayerItem(forVideo: video, options: options) { [weak self] playerItem, info in
            DispatchQueue.main.async {
                self?.playerItem = playerItem
                resultHandler(playerItem, info)
            }
        }
    }
}
