import AVKit

/// Indexes a video's samples to provide accurate timing information for each sample.
public class SampleTimeIndexer {

    public typealias Result = Swift.Result<SampleTimes, SampleTimeIndexError>

    public var qualityOfService: QualityOfService = .userInitiated {
        didSet { queue.qualityOfService = qualityOfService }
    }

    private lazy var queue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        queue.qualityOfService = qualityOfService
        return queue
    }()

    public init() {}

    deinit {
        cancel()
    }

    public func cancel() {
        queue.cancelAllOperations()
    }

    /// Indexes the video's samples to provide accurate timing information for each sample.
    ///
    /// - Parameters:
    ///   - asset: The asset to index. The asset must have a video track to read samples from.
    ///   - limit: The maximum number of samples to read before aborting.
    ///   - completionHandler: Is called on an arbitrary queue.
    public func indexTimes(
        for asset: AVAsset,
        limit: Int = .max,
        completionHandler: @escaping (Result) -> Void
    ) {
        let operation = SampleTimeIndexOperation(asset: asset, sampleLimit: limit) { result in
            completionHandler(result.map(SampleTimes.init))
        }

        queue.addOperation(operation)
    }
}
