import AVKit
import Photos

class VideoLoader {

    let asset: PHAsset

    private let imageManager: PHImageManager
    private var imageGenerator: AVAssetImageGenerator?

    private(set) var imageRequest: ImageManagerRequest?
    private(set) var downloadingPlayerItemRequest: ImageManagerRequest?

    init(asset: PHAsset, imageManager: PHImageManager = .default()) {
        self.asset = asset
        self.imageManager = imageManager
    }

    deinit {
        cancelAllRequests()
    }

    /// Pending image requests are canceled.
    func image(withSize size: CGSize, contentMode: PHImageContentMode, options: PHImageRequestOptions? = .default(), resultHandler: @escaping (UIImage?, ImageManagerRequest.Info) -> ()) {
        imageRequest = ImageRequest(imageManager: imageManager, asset: asset, targetSize: size, contentMode: contentMode, options: options, resultHandler: resultHandler)
    }

    /// Pending download player item requests are canceled.
    /// If locally available, the item is served directly, otherwise downloaded from iCloud.
    func downloadingPlayerItem(withOptions options: PHVideoRequestOptions? = .default(), progressHandler: @escaping (Double) -> (), resultHandler: @escaping (AVPlayerItem?, ImageManagerRequest.Info) -> ()) {
        downloadingPlayerItemRequest = AVAssetRequest(imageManager: imageManager, video: asset, options: options, progressHandler: progressHandler) { asset, _, info in
            let playerItem = asset.flatMap(AVPlayerItem.init)
            resultHandler(playerItem, info)
        }
    }

    /// Pending frame requests are canceled.
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
        cancelFrameGeneration()
        imageRequest = nil
        downloadingPlayerItemRequest = nil
    }
}
