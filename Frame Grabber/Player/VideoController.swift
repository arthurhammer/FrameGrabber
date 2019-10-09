import AVKit
import Photos

class VideoController {

    let settings: UserDefaults
    let asset: PHAsset
    private(set) var video: AVAsset?
    private(set) var previewImage: UIImage?

    private var frameExporter: FrameExporter?
    private let imageManager: PHImageManager
    private let fileManager: FileManager
    private(set) var videoRequest: PHImageManager.Request?
    private(set) var imageRequest: PHImageManager.Request?

    init(asset: PHAsset, video: AVAsset? = nil, settings: UserDefaults = .standard, imageManager: PHImageManager = .default(), fileManager: FileManager = .default) {
        self.asset = asset
        self.video = video
        self.settings = settings
        self.imageManager = imageManager
        self.fileManager = fileManager
    }

    /// The video's actual dimensions if it is loaded, otherwise the Photo asset's dimensions.
    var dimensions: CGSize {
        video?.dimensions ?? asset.dimensions
    }

    var location: CLLocation? {
        asset.location
    }

    var creationDate: Date? {
        asset.creationDate
    }

    var frameRate: Float? {
        video?.frameRate
    }

    func cancelAllRequests() {
        cancelFrameGeneration()
        imageRequest = nil
        videoRequest = nil
    }

    // MARK: Video/Preview Image Generation

    /// If a video loading request is in progress, it is cancelled.
    /// If available, the item is served directly, otherwise downloaded from iCloud.
    /// Handlers are called on the main thread.
    func loadVideo(withOptions options: PHVideoRequestOptions? = .default(), progressHandler: @escaping (Double) -> (), completionHandler: @escaping (AVAsset?, PHImageManager.Info) -> ()) {
        videoRequest = imageManager.requestAVAsset(for: asset, options: options, progressHandler: progressHandler) { video, _, info in
            self.video = video
            completionHandler(video, info)
        }
    }


    /// If a video loading request is in progress, it is cancelled.
    /// The handler is called on the main thread.
    func loadPreviewImage(with size: CGSize, completionHandler: @escaping (UIImage?, PHImageManager.Info) -> ()) {
        let options = PHImageManager.ImageOptions(size: size, mode: .aspectFit, requestOptions: .default())
        imageRequest = imageManager.requestImage(for: asset, options: options) { [weak self] image, info in
            if let image = image {
                self?.previewImage =  image
            }
            completionHandler(image, info)
        }
    }

    // MARK: Frame Generation

    /// If a frame generation request is in progress, it is cancelled.
    /// In addition to the normal frame export failure modes, the request fails if no
    /// video has been loaded yet. In that case no progress object is returned.
    /// The handler is called on the main thread.
    func generateAndExportFrames(for times: [CMTime], completionHandler: @escaping (FrameExporter.Result) -> ()) -> Progress? {
        guard let video = video else {
            completionHandler(.init(repeating: .failed(nil), count: times.count))
            return nil
        }


        let request = frameRequest(for: times)
        frameExporter = FrameExporter(video: video)

        return frameExporter?.generateAndExportFrames(with: request) { [weak self] result in
            DispatchQueue.main.async {
                self?.frameExporter = nil
                completionHandler(result)
            }
        }
    }

    func cancelFrameGeneration() {
        frameExporter?.cancel()
    }

    func deleteFrames(for exportResult: FrameExporter.Result) {
        try? exportResult.urls.forEach(fileManager.removeItem)
    }

    private func frameRequest(for times: [CMTime]) -> FrameExporter.Request {
        let metadata = settings.includeMetadata
            ? CGImage.metadata(for: asset.creationDate, location: asset.location)
            : nil

        let encoding = ImageEncoding(format: settings.imageFormat, compressionQuality: settings.compressionQuality, metadata: metadata)

        return FrameExporter.Request(times: times, encoding: encoding, directory: nil)
    }
}
