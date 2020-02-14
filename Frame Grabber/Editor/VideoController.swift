import AVKit
import Photos
import Combine

/// Manages a single asset from the photo library and loads various representations for it.
/// Supported asset types are videos and live photos.
///
/// Temporary resources for that asset are written to the user's temporary directory
/// (exported frames and video data for live photos). Upon deinitializing, these resources
/// are deleted by clearing the user's temporary directory.
class VideoController {

    let asset: PHAsset
    private(set) var video: AVAsset?
    private(set) var previewImage: UIImage?

    enum Result<Error, Media> {
        case cancelled
        case failed(Error)
        case succeeded(Media)
    }

    private let settings: UserDefaults
    private let imageManager: PHImageManager
    private let resourceManager: PHAssetResourceManager
    private let fileManager: FileManager
    private var frameExport: FrameExport?

    private var exportedVideoURL: URL?
    private var exportedFrameURLs: [URL]?
    private var videoRequest: Cancellable?
    private var imageRequest: Cancellable?

    init(asset: PHAsset, video: AVAsset? = nil, settings: UserDefaults = .standard, imageManager: PHImageManager = .default(), resourceManager: PHAssetResourceManager = .default(), fileManager: FileManager = .default) {
        self.asset = asset
        self.video = video
        self.settings = settings
        self.imageManager = imageManager
        self.resourceManager = resourceManager
        self.fileManager = fileManager
    }

    deinit {
        cancelAllRequests()
        try? fileManager.clearTemporaryDirectory()
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

    // MARK: Loading Preview Images

    /// If an image loading request is in progress, it is cancelled. Upon success, the
    /// `previewImage` property is set to the loaded image. Handlers are called on the main
    /// thread.
    func loadPreviewImage(with size: CGSize, completionHandler: @escaping (UIImage?, PHImageManager.Info) -> ()) {
        let options = PHImageManager.ImageOptions(size: size, mode: .aspectFit, requestOptions: .default())

        imageRequest = imageManager.requestImage(for: asset, options: options) { [weak self] image, info in
            if let image = image {
                self?.previewImage =  image
            }
            self?.imageRequest = nil  // (Note: This can execute synchronously, before the outer `imageRequest` is set, thus having no effect.)
            completionHandler(image, info)
        }
    }

    // MARK: Loading Videos

    /// Depending on type, calls `loadVideoForVideo` or `loadVideoForLivePhoto`.
    func loadVideo(progressHandler: @escaping (Double) -> (), completionHandler: @escaping (Result<Error?, AVAsset>) -> ()) {
        if asset.isLivePhoto {
            loadVideoForLivePhoto(progressHandler: progressHandler, completionHandler: completionHandler)
        } else {
            loadVideoForVideo(progressHandler: progressHandler, completionHandler: completionHandler)
        }
    }

    /// If a video loading request is in progress, it is cancelled. Upon success, the
    /// `video` property is set to the loaded video. Handlers are called on the main
    /// thread.
    func loadVideoForVideo(withOptions options: PHVideoRequestOptions? = .default(), progressHandler: @escaping (Double) -> (), completionHandler: @escaping (Result<Error?, AVAsset>) -> ()) {
        videoRequest = imageManager.requestAVAsset(for: asset, options: options, progressHandler: progressHandler) { [weak self] video, _, info in
            self?.video = video
            self?.videoRequest = nil

            if info.isCancelled {
                completionHandler(.cancelled)
            } else if let video = video {
                completionHandler(.succeeded(video))
            } else {
                completionHandler(.failed(info.error))
            }
        }
    }

    /// If a video loading request is in progress, it is cancelled. Previously loaded live
    /// photo videos are deleted. Upon success, the `video` property is set to the loaded
    /// video. Handlers are called on the main thread.
    func loadVideoForLivePhoto(withOptions options: PHAssetResourceRequestOptions? = .default(), progressHandler: @escaping (Double) -> (), completionHandler: @escaping (Result<Error?, AVAsset>) -> ()) {
        videoRequest = nil
        deleteExportedVideo()

        let finish = { [weak self] (result: Result<Error?, AVAsset>) in
            DispatchQueue.main.async {
                self?.videoRequest = nil
                self?.exportedVideoURL = (result.video as? AVURLAsset)?.url
                self?.video = result.video
                completionHandler(result)
            }
        }

        guard let videoResource = PHAssetResource.videoResource(forLivePhoto: asset) else {
            finish(.failed(nil))
            return
        }

        let fileURL: URL!

        do {
            let directory = try fileManager.createUniqueTemporaryDirectory()
            fileURL = directory.appendingPathComponent(videoResource.originalFilename)
        } catch let error {
            finish(.failed(error))
            return
        }

        videoRequest = resourceManager.requestAndWriteData(for: videoResource, toFile: fileURL, options: options, progressHandler: progressHandler) { error in
            if let error = error {
                finish(.failed(error))
                return
            }

            finish(.succeeded(AVURLAsset(url: fileURL)))
        }
    }

    func deleteExportedVideo() {
        try? exportedVideoURL.flatMap(fileManager.removeItem)
        exportedVideoURL = nil
    }

    // MARK: Exporting Frames

    /// If a frame generation request is already in progress, it is cancelled. Previously
    /// exported frames are deleted. Handlers are called on the main thread.
    func generateAndExportFrames(for times: [CMTime], updateHandler: @escaping (FrameExport.Status) -> ()) {
        cancelFrameExport()
        deleteExportedFrames()

        let finish = { [weak self] (status: FrameExport.Status) in
            DispatchQueue.main.async {
                self?.exportedFrameURLs = status.urls
                updateHandler(status)
            }
        }

        guard let video = video else {
            finish(.failed(nil))
            return
        }

        frameExport = FrameExport(request: frameRequest(for: video, times: times), fileManager: fileManager, updateHandler: finish)
        frameExport?.start()
    }

    func cancelFrameExport() {
        frameExport?.cancel()
        frameExport = nil
    }

    func deleteExportedFrames() {
        let urls = exportedFrameURLs ?? []
        try? urls.forEach(fileManager.removeItem)
        exportedFrameURLs = nil
    }

    private func frameRequest(for video: AVAsset, times: [CMTime]) -> FrameExport.Request {
        let metadata = settings.includeMetadata
            ? CGImage.metadata(for: asset.creationDate, location: asset.location)
            : nil

        let encoding = ImageEncoding(format: settings.imageFormat, compressionQuality: settings.compressionQuality, metadata: metadata)

        return .init(video: video, times: times, encoding: encoding, directory: nil, chunkSize: 5)
    }
}

extension VideoController.Result {
    var video: Media? {
        if case .succeeded(let video) = self {
            return video
        }
        return nil
    }
}
