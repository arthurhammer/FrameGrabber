import AVKit
import Photos

class VideoManager {

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

    func cancelAllRequests() {
        cancelFrameGeneration()
        imageRequest = nil
        downloadingPlayerItemRequest = nil
    }

    // MARK: Poster Image/Video Generation

    /// Pending image requests are cancelled.
    /// The result handler is called asynchronously on the main thread.
    func posterImage(withSize size: CGSize, contentMode: PHImageContentMode, options: PHImageRequestOptions? = .default(), resultHandler: @escaping (UIImage?, ImageManagerRequest.Info) -> ()) {
        imageRequest = ImageRequest(imageManager: imageManager, asset: asset, targetSize: size, contentMode: contentMode, options: options, resultHandler: resultHandler)
    }

    /// Pending downloading player item requests are cancelled.
    /// If locally available, the item is served directly, otherwise downloaded from iCloud.
    /// The progress and result handlers are called asynchronously on the main thread.
    func downloadingPlayerItem(withOptions options: PHVideoRequestOptions? = .default(), progressHandler: @escaping (Double) -> (), resultHandler: @escaping (AVPlayerItem?, ImageManagerRequest.Info) -> ()) {
        downloadingPlayerItemRequest = AVAssetRequest(imageManager: imageManager, video: asset, options: options, progressHandler: progressHandler) { asset, _, info in
            let playerItem = asset.flatMap(AVPlayerItem.init)
            resultHandler(playerItem, info)
        }
    }

    // MARK: Frame Generation

    var isGeneratingFrame: Bool {
        return imageGenerator != nil
    }

    /// Pending frame requests are canceled.
    /// The result handler is called asynchronously on the main thread.
    func frame(for avAsset: AVAsset, at time: CMTime, completionHandler: @escaping (AVAssetImageGenerator.Status) -> ()) {
        cancelFrameGeneration()
        
        imageGenerator = AVAssetImageGenerator(asset: avAsset)

        imageGenerator?.generateImage(at: time) { [weak self] result in
            DispatchQueue.main.async {
                self?.imageGenerator = nil
                completionHandler(result)
            }
        }
    }

    func cancelFrameGeneration() {
        imageGenerator?.cancelAllCGImageGeneration()
    }

    // MARK: Metadata Generation

    /// Adds metadata from the receiver's `PHAsset` (not from the actual video file).
    func jpgImageDataByAddingAssetMetadata(to image: UIImage, quality: CGFloat) -> Data? {
        let (_, metadata) = CGImageMetadata.for(creationDate: asset.creationDate, location: asset.location)
        return image.jpgImageData(withMetadata: metadata, quality: quality)
    }
}
