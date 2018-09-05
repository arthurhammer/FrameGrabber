import AVKit
import Photos

class VideoManager {

    let asset: PHAsset

    private let imageManager: PHImageManager
    private(set) var imageRequest: ImageRequest?
    private(set) var videoRequest: ImageRequest?

    init(asset: PHAsset, imageManager: PHImageManager = .default()) {
        self.asset = asset
        self.imageManager = imageManager
    }

    deinit {
        cancelAllRequests()
    }

    func cancelAllRequests() {
        imageRequest = nil
        videoRequest = nil
    }

    // MARK: Poster Image/Video Generation

    /// Pending requests of this type are cancelled.
    /// The result handler is called asynchronously on the main thread.
    func posterImage(with config: ImageConfig, resultHandler: @escaping (UIImage?, PHImageManager.Info) -> ()) {
        imageRequest = imageManager.requestImage(for: asset, config: config, resultHandler: resultHandler)
    }

    /// Pending requests of this type are cancelled.
    /// If available, the item is served directly, otherwise downloaded from iCloud.
    /// Handlers are called asynchronously on the main thread.
    func downloadingPlayerItem(withOptions options: PHVideoRequestOptions? = .default(), progressHandler: @escaping (Double) -> (), resultHandler: @escaping (AVPlayerItem?, PHImageManager.Info) -> ()) {
        videoRequest = imageManager.requestAVAsset(for: asset, options: options, progressHandler: progressHandler) { asset, _, info in
            resultHandler(asset.flatMap(AVPlayerItem.init), info)
        }
    }

    // MARK: Frame Generation

    /// Generates images synchronously.
    func currentFrame(for item: AVPlayerItem) -> UIImage? {
        let generator = AVAssetImageGenerator(asset: item.asset)
        generator.requestedTimeToleranceBefore = .zero
        generator.requestedTimeToleranceAfter = .zero
        generator.appliesPreferredTrackTransform = true

        let cgImage = try? generator.copyCGImage(at: item.currentTime(), actualTime: nil)
        return cgImage.flatMap(UIImage.init)
    }

    // MARK: Metadata Generation

    /// Adds metadata from the receiver's `PHAsset` (not from the actual video file).
    func jpgImageDataByAddingAssetMetadata(to image: UIImage, quality: CGFloat) -> Data? {
        let (_, metadata) = CGImageMetadata.for(creationDate: asset.creationDate, location: asset.location)
        return image.jpgImageData(withMetadata: metadata, quality: quality)
    }
}
