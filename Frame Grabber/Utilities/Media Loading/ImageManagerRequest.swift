import Photos

/// Base class for a `PHImageManager` request that automatically cancels on `deinit`.
class ImageManagerRequest {

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

    /// The handler is called asynchronously on the main thread
    init(imageManager: PHImageManager, asset: PHAsset, targetSize: CGSize, contentMode: PHImageContentMode, options: PHImageRequestOptions?, resultHandler: @escaping (UIImage?, [AnyHashable: Any]?) -> ()) {
        super.init(imageManager: imageManager)

        id = imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: contentMode, options: options) { [weak self] image, info in
            DispatchQueue.main.async {
                self?.image = image
                resultHandler(image, info)
            }
        }
    }
}

class PlayerItemRequest: ImageManagerRequest {

    var playerItem: AVPlayerItem?

    /// The handler is called asynchronously on the main thread
    init(imageManager: PHImageManager, video: PHAsset, options: PHVideoRequestOptions?, resultHandler: @escaping (AVPlayerItem?, [AnyHashable: Any]?) -> ()) {
        super.init(imageManager: imageManager)

        id = imageManager.requestPlayerItem(forVideo: video, options: options) { [weak self] playerItem, info in
            DispatchQueue.main.async {
                self?.playerItem = playerItem
                resultHandler(playerItem, info)
            }
        }
    }
}
