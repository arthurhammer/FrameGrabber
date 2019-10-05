import AVFoundation

/// Generates full-size video frames and saves them to disk.
/// Frames can be generated and saved in chunks to avoid memory pressure (this is
/// important especially for older devices for large images).
class FrameExporter {

    struct Request {
        let times: [CMTime]
        let encoding: ImageEncoding
        /// If nil, the exporter creates a directory in the user's temporary directory.
        let directory: URL?
    }

    typealias Result = [FrameExport.Result]

    let video: AVAsset
    let chunkSize: Int
    let fileManager: FileManager

    private lazy var generator: AVAssetImageGenerator = .default(for: video)

    private lazy var taskQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        queue.qualityOfService = .userInitiated
        return queue
    }()

    init(video: AVAsset, chunkSize: Int = 5, fileManager: FileManager = .default) {
        self.video = video
        self.chunkSize = chunkSize
        self.fileManager = fileManager
    }

    deinit {
        cancel()
    }

    /// Cancels the frame export. Images previously successfully written are not deleted.
    func cancel() {
        generator.cancelAllCGImageGeneration()
        cancelExportOperations()
    }

    func deleteFrames(for result: Result) {
        try? result.urls.forEach(fileManager.removeItem)
    }

    /// Generates frames and exports them to disk with the given request configuration.
    /// Handlers are called on an arbitrary queue.
    ///
    /// - Returns: A progress object that reports the number of processed frames and the
    ///   fraction of completeness. The progress object supports cancelling the task.
    @discardableResult func generateAndExportFrames(with request: Request, completionHandler: @escaping (Result) -> ()) -> Progress? {
        guard let directory = directory(for: request, errorHandler: completionHandler) else { return nil }

        // Since tasks are strictly sequential, modifying the array from different threads is safe.
        var results = Result()
        let chunks = request.times.chunked(into: chunkSize)
        let progress = Progress()

        progress.cancellationHandler = { [weak self] in self?.cancel() }
        progress.totalUnitCount = Int64(request.times.count)
        progress.update(withCompletedUnits: 0)

        chunks.enumerated().forEach { chunkIndex, times in
            let chunk = Request(times: times, encoding: request.encoding, directory: directory)
            let startIndex = chunkIndex * chunkSize

            taskQueue.addOperation(FrameExport(request: chunk, frameStartIndex: startIndex, generator: generator, progressHandler: { completedFrameIndex in
                progress.update(withCompletedUnits: completedFrameIndex + 1)
            }, completionHandler: {
                results.append(contentsOf: $0)
            }))
        }

        taskQueue.addOperation {
            completionHandler(results)
        }

        return progress
    }

    /// The directory specified in the request if available or the URL to a newly created
    /// temporary one. If creation fails, invokes the handler and returns nil.
    private func directory(for request: Request, errorHandler: @escaping (Result) -> ()) -> URL? {
        var directory = request.directory

        if directory == nil {
            do {
                directory = try fileManager.createUniqueTemporaryDirectory()
            } catch let error {
                DispatchQueue.main.async {
                    errorHandler(.init(repeating: .failed(error), count: request.times.count))
                }
                return nil
            }
        }

        return directory
    }

    /// Cancels all export but not final result handler operations.
    private func cancelExportOperations() {
        taskQueue.operations.forEach {
            ($0 as? FrameExport)?.cancel()
        }
    }
}

// MARK: - Util

extension FrameExporter {
    /// Clears the user's temporary directory, the default directory for frame exports.
    static func clearTemporaryDirectory(with manager: FileManager = .default) throws {
        try manager.clearTemporaryDirectory()
    }
}

extension FrameExporter.Result {

    var anyCancelled: Bool {
        contains {
            if case .cancelled = $0 { return true }
            return false
        }
    }

    var anyFailed: Bool {
        contains {
            if case .failed = $0 { return true }
            return false
        }
    }

    /// All successfull frame results.
    var urls: [URL] {
        compactMap {
            if case .succeeded(let url) = $0 { return url }
            return nil
        }
    }
}

private extension Progress {
    func update(withCompletedUnits count: Int) {
        completedUnitCount = Int64(count)
        localizedDescription = NSLocalizedString("frame-export.title", value: "Generating Frames", comment: "Frame export activity title")
        let format = NSLocalizedString("frame-export.subtitle", value: "%@ of %@", comment: "Frame export activitiy subtitle, i.e. number of completed of total frames.")
        localizedAdditionalDescription = String.localizedStringWithFormat(format, completedUnitCount as NSNumber, totalUnitCount as NSNumber)
    }
}

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}
