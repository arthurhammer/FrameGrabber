import AVKit
import Photos

class VideoLoader {

    let asset: PHAsset

    private let imageManager: PHImageManager
    private var imageGenerator: AVAssetImageGenerator?

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

    /// Pending frame requests are canceled
    func frame(for avAsset: AVAsset, at time: CMTime, resultHandler: @escaping AVAssetImageGeneratorCompletionHandler) {
        cancelFrameGeneration()
        imageGenerator = AVAssetImageGenerator(asset: avAsset)

        imageGenerator?.generateImage(at: time) { [weak self] requestedTime, cgImage, actualTime, status, error in
            DispatchQueue.main.async {
                self?.imageGenerator = nil
                resultHandler(requestedTime, cgImage, actualTime, status, error)
            }
        }
    }

    func cancelFrameGeneration() {
        imageGenerator?.cancelAllCGImageGeneration()
    }

    func cancelAllRequests() {
        imageRequest = nil
        playerItemRequest = nil
        cancelFrameGeneration()
    }
}
