import AVKit
import os.log

public protocol SampleTimeIndexer {
    func indexTimes(for asset: AVAsset, completionHandler: @escaping (Result<SampleTimes, Error>) -> Void)
    func cancel()
}

/// Indexes a video's samples to provide accurate timing information for each sample.
@available(iOS, deprecated: 16.0, message: "Migrate to `AVSampleCursor`.")
public class SampleTimeIndexerImpl: SampleTimeIndexer {

    private struct Request {
        let asset: AVAsset
        let sampleLimit: Int
        let shouldRetry: (SampleTimeIndexError) -> Bool
        let completionHandler: (Result) -> Void
    }
    
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
    
    private lazy var logger: Logger? = .module

    public init() {}

    deinit {
        cancel()
    }

    public func cancel() {
        queue.cancelAllOperations()
    }
    
    public func indexTimes(for asset: AVAsset, completionHandler: @escaping (Swift.Result<SampleTimes, Error>) -> Void) {
        indexTimes(for: asset, sampleLimit: .max, shouldRetry: { $0.isInterrupted }) { result in
            completionHandler(result.mapError { $0 })
        }
    }
    
    /// Indexes the video's samples to provide accurate timing information for each sample.
    ///
    /// The app must remain in the foreground while indexing or it will fail with an `.interrupted`
    /// error. If so, the indexer offers to retry the operation. Retrying starts from the beginning
    /// and any samples indexed so far are discarded.
    ///
    /// - Parameters:
    ///   - asset: The asset to index. The asset must have a video track to read samples from.
    ///   - limit: The maximum number of samples to read before aborting.
    ///   - shouldRetry: Whether to retry the operation in case of error. Is called on an arbitrary
    ///     queue.
    ///   - completionHandler: Is called after completing any potential retries. Is called on an
    ///     arbitrary queue.
    public func indexTimes(
        for asset: AVAsset,
        sampleLimit: Int = .max,
        shouldRetry: @escaping (SampleTimeIndexError) -> Bool = { _ in false },
        completionHandler: @escaping (Result) -> Void
    ) {
        let request = Request(
            asset: asset,
            sampleLimit: sampleLimit,
            shouldRetry: shouldRetry,
            completionHandler: completionHandler
        )
        
        perform(request: request)
    }
    
    private func perform(request: Request) {
        logger?.debug("Enqueuing operation.")
        
        let operation = SampleTimeIndexOperation(
            asset: request.asset,
            sampleLimit: request.sampleLimit,
            completionHandler: { [weak self] result in
                self?.handleResult(result, for: request)
            }
        )

        queue.addOperation(operation)
    }
    
    // todo: enhance to resume from the last aborted sample instead of re-starting fully.
    private func handleResult(_ result: Result, for request: Request) {
        switch result {
        case .failure(let error):
            logger?.info("Finished with error: \(String(describing: error))")
            
            if request.shouldRetry(error) {
                DispatchQueue.main.async {
                    self.logger?.info("Retrying.")
                    self.perform(request: request)
                }
            } else {
                request.completionHandler(result)
            }
        case .success(let times):
            logger?.info("Finished successfully.")
            logger?.info("\t\(times.values.count) samples.")

            request.completionHandler(result)
        }
    }
}
