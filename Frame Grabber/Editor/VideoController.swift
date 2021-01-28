import UIKit
import AVFoundation
import Photos
import Combine

/// Manages a video or Live Photo asset from the photo library. Loads and exports various
/// representations for the asset.
///
/// Temporary resources for that asset are written to the user's temporary directory
/// (exported frames and video data for live photos). Upon deinitializing, these resources
/// are deleted by clearing the user's temporary directory.
class VideoController {

    typealias VideoResult = Result<AVAsset, Error?>

    let source: VideoSource
    private(set) var video: AVAsset?
    private(set) var previewImage: UIImage?

    // MARK: Private Properties

    private let settings: UserDefaults
    private let imageManager: PHImageManager
    private let resourceManager: PHAssetResourceManager
    private let fileManager: FileManager
    private var frameExport: FrameExport?

    private var exportedVideoURL: URL?
    private var exportedFrameURLs: [URL]?
    private var videoRequest: Cancellable?
    private var imageRequest: Cancellable?

    init(
        source: VideoSource,
        video: AVAsset? = nil,
        previewImage: UIImage? = nil,
        settings: UserDefaults = .standard,
        imageManager: PHImageManager = .default(),
        resourceManager: PHAssetResourceManager = .default(),
        fileManager: FileManager = .default
    ) {
        self.source = source
        self.video = video
        self.previewImage = previewImage
        self.settings = settings
        self.imageManager = imageManager
        self.resourceManager = resourceManager
        self.fileManager = fileManager
    }

    deinit {
        cancelAllRequests()
        try? fileManager.clearTemporaryDirectory()
    }

    // MARK: Cancelling

    func cancelAllRequests() {
        cancelPreviewImageLoading()
        cancelVideoLoading()
        cancelFrameExport()
    }

    // MARK: Loading Preview Images

    /// Upon success, the `previewImage` property is set to the loaded image.
    ///
    /// If an image loading request is already in progress, it is cancelled. Check the
    /// info dictionary in the completion handler if the request was cancelled.
    ///
    /// Handlers are called on the main thread.
    func loadPreviewImage(with size: CGSize, completionHandler: @escaping (UIImage?, PHImageManager.Info) -> ()) {
        guard case let .photoLibrary(libraryAsset) = source else { return }
        
        let options = PHImageManager.ImageOptions(size: size, mode: .aspectFit, requestOptions: .default())

        imageRequest = imageManager.requestImage(for: libraryAsset, options: options) { [weak self] image, info in
            if let image = image {
                self?.previewImage = image
            }
            self?.imageRequest = nil  // (Note: This can execute synchronously, before the outer `imageRequest` is set, thus having no effect.)
            completionHandler(image, info)
        }
    }

    func cancelPreviewImageLoading() {
        imageRequest = nil
    }

    // MARK: Loading Videos

    /// Depending on the type of asset, calls `loadVideoForVideo` or `loadVideoForLivePhoto`
    /// with default request options.
    ///
    /// Upon success, the `video` property is set to the loaded video.
    ///
    /// If a video loading request is already in progress, it is cancelled. If the request
    /// is cancelled, calls the completion handler with a `CocoaError.userCancelled` error.
    ///
    /// Handlers are called on the main thread.
    func loadVideo(progressHandler: @escaping (Double) -> (), completionHandler: @escaping (VideoResult) -> ()) {
        switch source {
        
        case .url(let url):
            let video = AVAsset(url: url)
            self.video = video
            completionHandler(.success(video))
        
            
        case .photoLibrary(let asset) where asset.isVideo:
            loadVideoForVideo(
                progressHandler: progressHandler,
                completionHandler: completionHandler
            )
                
        case .photoLibrary(let asset) where asset.isLivePhoto:
            loadVideoForLivePhoto(
                progressHandler: progressHandler,
                completionHandler: completionHandler
            )
            
        default:
            assertionFailure("Unknown video source")
        }
    }

    /// See `loadVideo(progressHandler:completionHandler:)`
    func loadVideoForVideo(withOptions options: PHVideoRequestOptions = .default(),
                           progressHandler: @escaping (Double) -> (),
                           completionHandler: @escaping (VideoResult) -> ()) {

        guard case let .photoLibrary(libraryAsset) = source else { return }

        videoRequest = imageManager.requestAVAsset(for: libraryAsset, options: options, progressHandler: progressHandler) { [weak self] video, _, info in
            self?.video = video
            self?.videoRequest = nil

            if info.isCancelled {
                completionHandler(.failure(CocoaError(.userCancelled)))
            } else if let video = video {
                completionHandler(.success(video))
            } else {
                completionHandler(.failure(info.error))
            }
        }
    }

    /// See `loadVideo(progressHandler:completionHandler:)`.
    func loadVideoForLivePhoto(withOptions options: PHAssetResourceRequestOptions = .default(),
                               progressHandler: @escaping (Double) -> (),
                               completionHandler: @escaping (VideoResult) -> ()) {

        guard case let .photoLibrary(libraryAsset) = source else { return }
        
        videoRequest = nil
        deleteExportedVideo()

        let completion = { [weak self] (result: Result<URL, Error?>) in
            let videoResult = result.map { AVAsset(url: $0) }
            self?.videoRequest = nil
            self?.video = videoResult.value
            self?.exportedVideoURL = result.value
            completionHandler(videoResult)
        }

        guard let videoResource = PHAssetResource.videoResource(forLivePhoto: libraryAsset) else {
            completion(.failure(nil))
            return
        }

        let directory: URL

        do {
            directory = try fileManager.createUniqueDirectory()
        } catch {
            completion(.failure(error))
            return
        }

        let fileUrl = directory.appendingPathComponent(videoResource.originalFilename)

        videoRequest = resourceManager.requestAndWriteData(for: videoResource, toFile: fileUrl, options: options, progressHandler: progressHandler) { result in
            completion( result.mapError { $0 } )
        }
    }

    func cancelVideoLoading() {
        videoRequest = nil
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

        let completion = { [weak self] (status: FrameExport.Status) in
            DispatchQueue.main.async {
                self?.exportedFrameURLs = status.urls
                updateHandler(status)
            }
        }

        guard let video = video else {
            completion(.failed(nil))
            return
        }

        frameExport = FrameExport(request: frameRequest(for: video, from: source, times: times), fileManager: fileManager, updateHandler: completion)
        frameExport?.start()
    }

    func cancelFrameExport() {
        frameExport?.cancel()
    }

    func deleteExportedFrames() {
        let urls = exportedFrameURLs ?? []
        try? urls.forEach(fileManager.removeItem)
        exportedFrameURLs = nil
    }

    private func frameRequest(for video: AVAsset, from source: VideoSource, times: [CMTime]) -> FrameExport.Request {
        let metadata = settings.includeMetadata
            ? self.metadata(for: video, from: source)
            : nil
        
        let encoding = ImageEncoding(
            format: settings.imageFormat,
            compressionQuality: settings.compressionQuality,
            metadata: metadata
        )

        return FrameExport.Request(
            video: video,
            times: times,
            encoding: encoding,
            directory: nil,
            chunkSize: 5
        )
    }
    
    /// Combined metadata from the asset's photo library metadata and the video file itself.
    ///
    /// - Note: Video metadata is loaded synchronously and can block.
    ///
    /// - TODO: Load video metadata asynchronously using `AVAsynchronousKeyValueLoading`.   
    private func metadata(for video: AVAsset, from source: VideoSource) -> ImageMetadata {
        // Prefer photo library data over video data.
        let photoLibraryLocation = source.asset?.location
        let photoLibraryCreationDate = source.asset?.creationDate
        
        // Rest from video metadata directly.
        let videoMetadata = video.commonMetadata
        
        let make = metadataString(for: .commonIdentifierMake, in: videoMetadata)
        let model = metadataString(for: .commonIdentifierModel, in: videoMetadata)
        let software = metadataString(for: .commonIdentifierSoftware, in: videoMetadata)
        
        let creationDate = photoLibraryCreationDate ?? video.creationDate?.dateValue
        let comment = UserText.exifAppInformation
                        
        return ImageMetadata.metadata(
            forCreationDate: creationDate,
            location: photoLibraryLocation,
            make: make,
            model: model,
            software: software,
            userComment: comment
        )
    }
    
    private func metadataString(for id: AVMetadataIdentifier, in metadata: [AVMetadataItem]) -> String? {
        AVMetadataItem.metadataItems(from: metadata, filteredByIdentifier: id).first?.stringValue
    }
}
