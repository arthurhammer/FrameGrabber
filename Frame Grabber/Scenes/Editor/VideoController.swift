@preconcurrency import AVFoundation
import Combine
import Photos
import UIKit

// Note: This class has several issues and should be rewritten and split up.

/// Manages a video or Live Photo asset from the photo library or external location. Loads and
/// exports various representations for the asset.
///
/// The controller writes temporary resources to the user's temporary directory and clears the
/// resources upon deinitalization.
///
/// - Note: The controller should only be used from the main queue.
class VideoController {

    typealias VideoResult = Result<AVAsset, Error?>

    let source: VideoSource
    private(set) var video: AVAsset?
    private(set) var previewImage: UIImage?

    // MARK: Private Properties

    private let settings: UserDefaults
    private let fileManager: FileManager
    
    // Photo Library
    private let imageManager: PHImageManager
    private var videoRequest: Cancellable?
    private var imageRequest: Cancellable?
    
    // Live Photo
    private let resourceManager: PHAssetResourceManager
    private var livePhotoVideoURL: URL?
    
    // External Video
    private var imageGenerator: AVAssetImageGenerator?
    
    // Frame Export
    private var frameExport: FrameExport?
    private var exportedFrameURLs: [URL]?

    /// - Parameters:
    ///   - source: The controller takes ownership of the resource. If the source type is `.url`,
    ///     the controller deletes the file upon deinitialization. If required, create a local copy
    ///     of the resource.
    ///   - video: If available, the video already loaded from the source.
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
        self.video = video ?? source.url.flatMap(AVAsset.init(url:))
        self.previewImage = previewImage
        self.settings = settings
        self.imageManager = imageManager
        self.resourceManager = resourceManager
        self.fileManager = fileManager
    }

    deinit {
        cancelAllRequests()
        try? deleteAllResources()
    }

    // MARK: Cancelling
    
    func cancelAllRequests() {
        cancelPreviewImageLoading()
        cancelVideoLoading()
        cancelFrameExport()
    }
    
    func deleteAllResources() throws {
        try deleteVideoResource()
        try deleteLivePhotoResource()
        try deleteExportedFrames()
    }
    
    func deleteVideoResource() throws {
        guard let videoURL = source.url else { return }
        try fileManager.removeItem(at: videoURL)
    }

    // MARK: Loading Preview Images
    
    /// Upon success, the `previewImage` property is set to the loaded image.
    ///
    /// If an image loading request is already in progress, it is cancelled.
    ///
    /// Handlers are called on the main thread.
    func loadPreviewImage(
        with size: CGSize,
        completionHandler: @escaping (UIImage?) -> ()
    ) {
        cancelPreviewImageLoading()
        
        switch source {
        
        case .photoLibrary(let asset):
            loadPhotoLibraryPreviewImage(for: asset, with: size, completionHandler: completionHandler)
            
        case .url, .camera:
            assert(video != nil)
            generateVideoPreviewImage(for: video!, with: size, completionHandler: completionHandler)
        }
    }
    
    private func loadPhotoLibraryPreviewImage(
        for asset: PHAsset,
        with size: CGSize,
        completionHandler: @escaping (UIImage?) -> ()
    ) {
        let options = PHImageManager.ImageOptions(
            size: size,
            mode: .aspectFit,
            requestOptions: .default()
        )

        imageRequest = imageManager.requestImage(for: asset, options: options) {
            [weak self] image, info in
            
            self?.previewImage = image ?? self?.previewImage
            self?.imageRequest = nil
            completionHandler(image)
        }
    }
    
    private func generateVideoPreviewImage(
        for video: AVAsset,
        with size: CGSize,
        completionHandler: @escaping (UIImage?) -> ()
    ) {
        let sourceTime = [NSValue(time: .zero)]
        let imageGenerator = AVAssetImageGenerator(asset: video)
        self.imageGenerator = imageGenerator
        
        imageGenerator.maximumSize = size.applying(.init(scaleX: 1.5, y: 1.5))  // Add tolerance.
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.requestedTimeToleranceAfter = .positiveInfinity
        imageGenerator.requestedTimeToleranceBefore = .positiveInfinity
                
        imageGenerator.generateCGImagesAsynchronously(forTimes: sourceTime) {
            [weak self] _, image, _, _, _ in
            
            DispatchQueue.main.async {
                let image = image.flatMap(UIImage.init)
                self?.previewImage = image ?? self?.previewImage
                completionHandler(image)
            }
        }
    }

    func cancelPreviewImageLoading() {
        imageRequest = nil
        imageGenerator?.cancelAllCGImageGeneration()
    }

    // MARK: Loading Videos

    /// Depending on the type of the asset, loads the appropriate video representation and, upon
    /// success, sets the `video` property to the result.
    ///
    /// If `video` is not nil, immediately completes with its value. If a video loading request is
    /// currently in progress, it is cancelled. If the request is cancelled, calls the completion
    /// handler with a `CocoaError.userCancelled` error.
    ///
    /// Handlers are called on the main thread.
    func loadVideo(
        progressHandler: @escaping (Double) -> (),
        completionHandler: @escaping (VideoResult) -> ()
    ) {
        if let video {
            completionHandler(.success(video))
            return
        }
        
        cancelVideoLoading()
                
        switch source {
        
        case .url where video != nil:
            completionHandler(.success(video!))
            
        case .photoLibrary(let asset) where asset.isVideo:
            loadPhotoLibraryVideo(
                for: asset,
                progressHandler: progressHandler,
                completionHandler: completionHandler
            )
                
        case .photoLibrary(let asset) where asset.isLivePhoto:
            loadPhotoLibraryLivePhotoVideo(
                for: asset,
                progressHandler: progressHandler,
                completionHandler: completionHandler
            )
            
        default:
            assertionFailure("Unknown video source")
        }
    }
    
    private func loadPhotoLibraryVideo(
        for asset: PHAsset,
        withOptions options: PHVideoRequestOptions = .default(),
        progressHandler: @escaping (Double) -> (),
        completionHandler: @escaping (VideoResult) -> ()
    ) {
        videoRequest = imageManager.requestAVAsset(
            for: asset,
            options: options,
            progressHandler: progressHandler
        ) { [weak self] video, _, info in
            
            self?.video = video
            self?.videoRequest = nil

            if info.isCancelled {
                completionHandler(.failure(CocoaError(.userCancelled)))
            } else if let video {
                completionHandler(.success(video))
            } else {
                completionHandler(.failure(info.error))
            }
        }
    }

    private func loadPhotoLibraryLivePhotoVideo(
        for asset: PHAsset,
        withOptions options: PHAssetResourceRequestOptions = .default(),
        progressHandler: @escaping (Double) -> (),
        completionHandler: @escaping (VideoResult) -> ()
    ) {
        videoRequest = nil
        try? deleteLivePhotoResource()

        let completion = { [weak self] (result: Result<URL, Error?>) in
            let videoResult = result.map { AVAsset(url: $0) }
            self?.videoRequest = nil
            self?.video = videoResult.value
            self?.livePhotoVideoURL = result.value
            completionHandler(videoResult)
        }

        guard let videoResource = PHAssetResource.videoResource(forLivePhoto: asset) else {
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

        videoRequest = resourceManager.requestAndWriteData(
            for: videoResource,
            toFile: fileUrl,
            options: options,
            progressHandler: progressHandler
        ) { result in
            completion( result.mapError { $0 } )
        }
    }

    func cancelVideoLoading() {
        videoRequest = nil
    }

    func deleteLivePhotoResource() throws {
        try livePhotoVideoURL.flatMap(fileManager.removeItem)
        livePhotoVideoURL = nil
    }

    // MARK: Exporting Frames

    /// If a frame generation request is already in progress, it is cancelled. Previously exported
    /// frames are deleted. Handlers are called on the main thread.
    func generateAndExportFrames(
        for times: [CMTime],
        updateHandler: @escaping (FrameExport.Status) -> ()
    ) {
        cancelFrameExport()
        try? deleteExportedFrames()
        
        let completion = { [weak self] (status: FrameExport.Status) in
            DispatchQueue.main.async {
                self?.exportedFrameURLs = status.urls
                updateHandler(status)
            }
        }

        guard let video else {
            completion(.failed(nil))
            return
        }
        
        // Bug: This task should also be cancelled with `cancelFrameExport`, otherwise several exports can be started
        // simultaneously leading to incosistent state.
        Task {
            let metadata = try await video.loadMetadata()
            
            DispatchQueue.main.async { [self] in // Sync property access.
                let request = frameRequest(
                    for: video,
                    at: times,
                    source: self.source,
                    metadata: metadata
                )

                frameExport = FrameExport(
                    request: request,
                    fileManager: self.fileManager,
                    updateHandler: completion
                )

                frameExport?.start()
            }
        }
    }

    func cancelFrameExport() {
        frameExport?.cancel()
    }

    func deleteExportedFrames() throws {
        let urls = exportedFrameURLs ?? []
        try urls.forEach(fileManager.removeItem)
        exportedFrameURLs = nil
    }

    private func frameRequest(
        for video: AVAsset,
        at times: [CMTime],
        source: VideoSource,
        metadata: VideoMetadata
    ) -> FrameExport.Request {
        
        let metadata = settings.includeMetadata
            ? self.metadata(for: metadata, from: source)
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
    private func metadata(for videoMetadata: VideoMetadata, from source: VideoSource) -> ImageMetadata {
        // Prefer photo library data over video data.
        let location = (source.photoLibraryAsset?.location) ?? (videoMetadata.common?.location)
        let creationDate = (source.photoLibraryAsset?.creationDate) ?? (videoMetadata.creationDate)

        return ImageMetadata.metadata(
            forCreationDate: creationDate,
            location: location,
            make: videoMetadata.common?.make,
            model: videoMetadata.common?.model,
            software: videoMetadata.common?.software,
            userComment: Localized.exifAppInformation
        )
    }
}
