import AVFoundation

/// Generates full-size video frames and saves them to disk.
///
/// Frames are generated and saved in chunks to avoid memory pressure (this is
/// important especially for older devices for large images).
class FrameExporter {

    struct Request {
        let video: AVAsset
        let times: [CMTime]
        let encoding: ImageEncoding
        /// If nil, the exporter creates a directory in the user's temporary directory.
        let directory: URL?
    }

    enum Result {
        case cancelled
        case failed(Error?)
        case succeeded([URL])
    }

    let request: Request

    private let chunkSize: Int
    private let progressHandler: (Int, Int) -> ()
    private let completionHandler: (Result) -> ()
    private let fileManager: FileManager

    private lazy var taskQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        queue.qualityOfService = .userInitiated
        return queue
    }()

    /// Handlers are called on an arbitrary queue.
    /// - parameter progressHandler: Called with the number of successfully processed and
    ///   the number of total frames to process.
    init(request: Request, chunkSize: Int = 5, fileManager: FileManager = .default, progressHandler: @escaping (Int, Int) -> (), completionHandler: @escaping (Result) -> ()) {
        self.request = request
        self.chunkSize = chunkSize
        self.fileManager = fileManager
        self.progressHandler = progressHandler
        self.completionHandler = completionHandler
    }

    deinit {
        cancel()
    }

    /// Starts the export.
    ///
    /// When the export is cancelled or any one frame export fails for any reason,
    /// previously successfully written frames are deleted.
    ///
    /// - Note: The export is one-shot and cannot be started again. Doing so is undefined.
    func start() {
        let directoryResult = directory(for: request)

        guard let directory = directoryResult.url else {
            completionHandler(.failed(directoryResult.error))
            return
        }

        let generator = AVAssetImageGenerator.default(for: request.video)
        let requestedTimes = request.times
        let subtasks = requestedTimes.chunked(into: chunkSize)

        subtasks.enumerated().forEach { taskIndex, chunk in
            let subrequest = Request(video: request.video, times: chunk, encoding: request.encoding, directory: directory)
            let startIndex = taskIndex * chunkSize

            let task = FrameExport(generator: generator, request: subrequest, frameStartIndex: startIndex) { [weak self] _, frameResult in
                self?.updateOverallResult(with: frameResult)
            }

            taskQueue.addOperation(task)
        }
    }

    /// Cancels the frame export.
    func cancel() {
        // Manually update the status. It's not sufficient to just cancel subtasks in the
        // queue for the following reasons:
        //
        // a) The overall task can still be cancelled in the brief window of all subtasks
        //    having finished successfully and the completion handler being called.
        // b) Pending cancelled subtasks in the queue are never started and as such don't
        //    report their status (including cancellation). We might omit recording
        //    cancellation in that case and finish successfully.
        updateOverallResult(with: .cancelled)
        taskQueue.cancelAllOperations()
    }

    /// Deletes all image files in the result.
    func deleteFiles(in result: Result) {
        guard case .succeeded(let urls) = result else { return }
        try? urls.forEach(fileManager.removeItem)
    }

    private var overallResult: Result = .succeeded([])  // (Access needs to be synchronized.)
    private var isFinished = false  // (Access needs to be synchronized.)
    private lazy var accessQueue = DispatchQueue(label: "", attributes: .concurrent)

    /// Synchronizes and updates the overall result from intermediate results.
    /// Can be called from multiple threads safely.
    private func updateOverallResult(with frameResult: Result) {
        accessQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }

            // When cancelling after finished, don't delete results.
            guard !self.isFinished else { return }

            let complete = { (result: Result) in
                self.overallResult = result
                self.completionHandler(result)
                self.isFinished = true
            }

            switch (self.overallResult, frameResult) {

            // A single frame was exported successfully.
            case (.succeeded(let urls), .succeeded(let url)):
                let newUrls = urls + url
                self.overallResult = .succeeded(newUrls)
                self.progressHandler(newUrls.count, self.request.times.count)

                // All tasks finished successfully, complete.
                if newUrls.count == self.request.times.count {
                    complete(.succeeded(newUrls))
                }

            // Initial cancellation. Delete results, complete.
            case (.succeeded, .cancelled):
                self.deleteFiles(in: self.overallResult)
                complete(.cancelled)

            // Initial failure. Cancel pending tasks, delete results, complete.
            case (.succeeded, .failed(let error)):
                self.cancel()
                self.deleteFiles(in: self.overallResult)
                complete(.failed(error))

            // Subsequent cancellations/failures or invalid transitions.
            case (.cancelled, _), (.failed, _):
                break
            }
        }
    }

    private func directory(for request: Request) -> (url: URL?, error: Error?) {
        var directory = request.directory

        if directory == nil {
            do {
                directory = try fileManager.createUniqueTemporaryDirectory()
            } catch let error {
                return (nil, error)
            }
        }

        return (directory, nil)
    }

}

// MARK: - Util

extension FrameExporter {
    /// Clears the user's temporary directory, the default directory for frame exports.
    static func clearTemporaryDirectory(with fileManager: FileManager = .default) throws {
        try fileManager.clearTemporaryDirectory()
    }
}

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}
