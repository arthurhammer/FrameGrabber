import AVFoundation

/// Generates and exports full-size video frames.
///
/// Since generating a large number of full-sized frames is very memory intensive, the
/// export generates and writes frames in separate chunks at time. For older devices
/// and/or large videos, use a rather low chunk size.
class FrameExport {

    struct Request {
        let video: AVAsset
        let times: [CMTime]
        let encoding: ImageEncoding
        /// If nil, the exporter creates a directory in the user's temporary directory.
        let directory: URL?
        let chunkSize: Int
    }

    enum Status {
        case cancelled
        case failed(Error?)
        case progressed([URL])
        case succeeded([URL])
    }

    let request: Request

    private let updateHandler: (Status) -> ()
    private let fileManager: FileManager

    private lazy var taskQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        queue.qualityOfService = .userInitiated
        return queue
    }()

    /// Handlers are called on an arbitrary queue.
    init(request: Request, fileManager: FileManager = .default, updateHandler: @escaping (Status) -> ()) {
        self.request = request
        self.fileManager = fileManager
        self.updateHandler = updateHandler
    }

    deinit {
        cancel()
    }

    /// Starts the export.
    ///
    /// When the export is cancelled (but not yet finished) or any one frame export fails
    /// for any reason, successfully exported frames so far are deleted. On success,
    /// returns the URLs to the exported frames. In that case, the caller is responsible
    /// for deleting frames when they are not needed anymore, e.g. with `deleteFiles(in:)`.
    ///
    /// Failure modes include:
    /// - The temporary export directory could not be created.
    /// - Any one of the requested frames could not be generated.
    /// - Generated frames could not be encoded with the requested encoding.
    /// - Encoded images could not be written to disk.
    ///
    /// - Note: The export is one-shot and cannot be started again.
    func start() {
        precondition(!didStart, "Export already started. Use a new instance to make a new request.")
        didStart = true

        var directory: URL!

        do {
            directory = try request.directory ?? fileManager.createUniqueTemporaryDirectory()
        } catch let error {
            updateHandler(.failed(error))
            return
        }

        let generator = AVAssetImageGenerator.default(for: request.video)
        let requestedTimes = request.times
        let subtasks = requestedTimes.chunked(into: request.chunkSize)

        subtasks.enumerated().forEach { taskIndex, chunk in
            let subrequest = Request(video: request.video, times: chunk, encoding: request.encoding, directory: directory, chunkSize: NSNotFound)
            let startIndex = taskIndex * request.chunkSize

            let task = FrameExportTask(generator: generator, request: subrequest, frameStartIndex: startIndex) { [weak self] _, frameResult in
                self?.updateOverallResult(with: frameResult)
            }

            taskQueue.addOperation(task)
        }
    }

    /// Cancels the frame export.
    ///
    /// If the export is not yet finished, deletes any successfully written frames so far.
    /// If it is, has no effect.
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
    func deleteFiles(in status: Status) {
        let urls = status.urls ?? []
        try? urls.forEach(fileManager.removeItem)
    }

    // MARK: Private

    private var didStart = false
    private var status: Status = .progressed([])  // Access needs to be synchronized.
    private lazy var accessQueue = DispatchQueue(label: "", qos: .userInitiated, attributes: .concurrent)

    /// Synchronizes and updates the overall result from intermediate results.
    /// Can be called from multiple threads safely.
    private func updateOverallResult(with frameResult: Status) {
        accessQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }

            let complete = { (result: Status) in
                self.status = result
                self.updateHandler(result)
            }

            switch (self.status, frameResult) {

            // A single frame was exported successfully.
            case (.progressed(let urls), .succeeded(let url)):
                let newUrls = urls + url
                self.status = .progressed(newUrls)

                // All tasks finished successfully, complete.
                if newUrls.count == self.request.times.count {
                    complete(.succeeded(newUrls))
                } else {
                    self.updateHandler(self.status)
                }

            // Initial cancellation. Delete results, complete.
            case (.progressed, .cancelled):
                self.deleteFiles(in: self.status)
                complete(.cancelled)

            // Initial failure. Cancel pending tasks, delete results, complete.
            case (.progressed, .failed(let error)):
                self.deleteFiles(in: self.status)
                self.cancel()
                complete(.failed(error))

            // Invalid transitions.
            default:
                break
            }
        }
    }
}

// MARK: - Util

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}

extension FrameExport.Status {
    var urls: [URL]? {
        switch self  {
        case .progressed(let urls): return urls
        case .succeeded(let urls): return urls
        default: return nil
        }
    }
}
