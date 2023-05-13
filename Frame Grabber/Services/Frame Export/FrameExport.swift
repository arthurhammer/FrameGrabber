import AVFoundation

/// Generates and exports full-size video frames.
///
/// Since generating a large number of full-sized frames is very memory intensive, the
/// export generates and writes frames in separate chunks at time. For older devices
/// and/or large videos, use a rather low chunk size.
///
/// Legacy. Using async/await, this can be significantly simplified and be made much safer.
class FrameExport {

    struct Request {
        let video: AVAsset
        let times: [CMTime]
        let encoding: ImageEncoding
        /// The parent directory in which the exporter creates the export directory.
        /// If nil, uses the user's temporary directory.
        let directory: URL?
        /// The maximum number of frames the exporter generates simultaneously.
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
    private var exportDirectory: URL?

    private lazy var taskQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        queue.qualityOfService = .default
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
    /// for any reason, the exporter attempts to delete exported frames so far.
    ///
    /// Failure modes include:
    ///
    /// - The export directory could not be created.
    /// - Any one of the requested frames could not be generated.
    /// - Generated frames could not be encoded with the requested encoding.
    /// - Encoded images could not be written to disk.
    ///
    /// - Note: The export is one-shot and cannot be started again.
    func start() {
        precondition(!didStart, "Export already started. Use a new instance to make a new request.")
        didStart = true

        let parentDirectory = request.directory ?? fileManager.temporaryDirectory

        do {
            exportDirectory = try fileManager.createUniqueDirectory(in: parentDirectory)
        } catch {
            updateHandler(.failed(error))
            return
        }

        let generator = AVAssetImageGenerator.default(for: request.video)
        let requests = subrequests(for: request, directory: exportDirectory).enumerated()

        requests.forEach { index, subrequest in
            let startIndex = index * request.chunkSize

            let task = FrameExportOperation(generator: generator, request: subrequest, frameStartIndex: startIndex) { [weak self] _, frameResult in
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

    // MARK: Private

    private func subrequests(for request: Request, directory: URL?) -> [Request] {
        request.times.chunked(into: request.chunkSize).map {
            Request(video: request.video,
                    times: $0,
                    encoding: request.encoding,
                    directory: directory,
                    chunkSize: request.chunkSize)
        }
    }

    private func rollback() throws {
        try exportDirectory.flatMap(fileManager.removeItem)
    }

    private var didStart = false
    private var status: Status = .progressed([])  // Access needs to be synchronized.
    private lazy var accessQueue = DispatchQueue(label: "", qos: .userInitiated, attributes: .concurrent)

    /// Synchronizes and updates the overall result from intermediate results.
    /// Can be called from multiple threads safely.
    private func updateOverallResult(with frameResult: Status) {
        accessQueue.async(flags: .barrier) { [weak self] in
            guard let self else { return }

            let update = { (result: Status) in
                self.status = result
                self.updateHandler(result)
            }

            switch (self.status, frameResult) {

            // A single frame was exported successfully.
            case (.progressed(let urls), .succeeded(let url)):
                let newUrls = urls + url

                // All tasks finished successfully, complete.
                if newUrls.count == self.request.times.count {
                    update(.succeeded(newUrls))
                } else {
                    update(.progressed(newUrls))
                }

            // Initial cancellation. Delete results, complete.
            case (.progressed, .cancelled):
                try? self.rollback()
                update(.cancelled)

            // Initial failure. Cancel pending tasks, delete results, complete.
            case (.progressed, .failed(let error)):
                try? self.rollback()
                self.cancel()
                update(.failed(error))

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
