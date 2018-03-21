import AVKit
import Photos

class VideoLoader {

    let asset: PHAsset

    private let imageManager: PHImageManager
    private(set) var imageRequest: ImageRequest?
    private(set) var playerItemRequest: PlayerItemRequest?

    init(asset: PHAsset, imageManager: PHImageManager = .default()) {
        self.asset = asset
        self.imageManager = imageManager
    }

    deinit {
        cancelAllRequests()
    }

    /// Pending image requests are canceled
    func image(withSize size: CGSize, contentMode: PHImageContentMode, options: PHImageRequestOptions? = .default(), resultHandler: @escaping (UIImage?, ImageManagerRequest.Info) -> ()) {
        imageRequest = ImageRequest(imageManager: imageManager, asset: asset, targetSize: size, contentMode: contentMode, options: options, resultHandler: resultHandler)
    }

    /// Pending player item requests are canceled
    func playerItem(withOptions options: PHVideoRequestOptions? = .default(), resultHandler: @escaping (AVPlayerItem?, ImageManagerRequest.Info) -> ()) {
        playerItemRequest = PlayerItemRequest(imageManager: imageManager, video: asset, options: options, resultHandler: resultHandler)
    }

    func cancelAllRequests() {
        imageRequest = nil
        playerItemRequest = nil
    }
}
