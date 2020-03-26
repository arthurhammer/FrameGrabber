import AVKit

/// Indexes frames in a video for their frame presentation time stamps.
class FrameIndexer {

    typealias IndexResult = Result<IndexedFrames, FrameIndexOperation.IndexError>

    var qualityOfService: QualityOfService = .userInitiated {
        didSet { queue.qualityOfService = qualityOfService }
    }

    private lazy var queue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        queue.qualityOfService = qualityOfService
        return queue
    }()

    deinit {
        cancel()
    }

    func cancel() {
        queue.cancelAllOperations()
    }

    /// - Parameters:
    ///   - video: The video to index.
    ///   - frameLimit: The maximum number of frames to read.
    ///   - completionHandler: Called on an arbitrary queue.
    func indexFrames(
        for video: AVAsset,
        frameLimit: Int = .max,
        completionHandler: @escaping (IndexResult) -> Void
    ) {
        let operation = FrameIndexOperation(video: video, frameLimit: frameLimit) { result in
            let result = result.map(IndexedFrames.init)
            completionHandler(result)
        }

        queue.addOperation(operation)
    }
}
