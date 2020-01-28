import AVKit
import Photos

class VideoController {

    let asset: PHAsset
    private(set) var video: AVAsset?
    private(set) var previewImage: UIImage?
    let settings: UserDefaults

    private var frameExporter: FrameExporter?
    private let imageManager: PHImageManager
    private(set) var videoRequest: PHImageManager.Request?
    private(set) var imageRequest: PHImageManager.Request?

    init(asset: PHAsset, video: AVAsset? = nil, settings: UserDefaults = .standard, imageManager: PHImageManager = .default()) {
        self.asset = asset
        self.video = video
        self.settings = settings
        self.imageManager = imageManager
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
        cancelFrameExport()
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

    // MARK: Frame Generation/Export

    /// If a frame generation request is in progress, it is cancelled.
    /// Handlers are called on the main thread.
    func generateAndExportFrames(for times: [CMTime], progressHandler: @escaping (Int, Int) -> (), completionHandler: @escaping (FrameExporter.Result) -> ()) {
        guard let video = video else {
            DispatchQueue.main.async {
                completionHandler(.failed(nil))
            }
            return
        }

        frameExporter = FrameExporter(request: exportRequest(for: video, times: times), progressHandler: { completed, total in
            DispatchQueue.main.async {
                progressHandler(completed, total)
            }
        }, completionHandler: { result in
            DispatchQueue.main.async {
                completionHandler(result)
            }
        })

        frameExporter?.start()
    }

    func cancelFrameExport() {
        frameExporter?.cancel()
    }

    func deleteFrames(for urls: [URL], with fileManager: FileManager = .default) {
        try? urls.forEach(fileManager.removeItem)
    }

    private func exportRequest(for video: AVAsset, times: [CMTime]) -> FrameExporter.Request {
        let metadata = settings.includeMetadata
            ? CGImage.metadata(for: asset.creationDate, location: asset.location)
            : nil

        let encoding = ImageEncoding(format: settings.imageFormat, compressionQuality: settings.compressionQuality, metadata: metadata)

        return .init(video: video, times: times, encoding: encoding, directory: nil)
    }
}
