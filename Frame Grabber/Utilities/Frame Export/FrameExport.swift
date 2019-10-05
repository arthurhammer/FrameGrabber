import AVFoundation

/// Generates full-size video frames and saves them to disk.
class FrameExport: Operation {

    enum Result {
        case cancelled
        case failed(Error?)
        case succeeded(URL)
    }

    let request: FrameExporter.Request
    let frameStartIndex: Int
    let generator: AVAssetImageGenerator
    let progressHandler: (Int) -> ()
    let completionHandler: ([Result]) -> ()

    /// Handlers are called on an arbitrary queue.
    ///
    /// - Parameter frameStartIndex: If the task represents a chunk of a larger task, the
    ///   index describes the index of generated frames relative to the larger task. The
    ///   value is also used to generate file names for exported images.
    /// - Parameter progressHandler: Called with the index (offset by `startIndex`) of
    ///   the currently processed image.
    /// - Parameter completionHandler: Called when all images have been processed.
    init(request: FrameExporter.Request,
         frameStartIndex: Int = 0,
         generator: AVAssetImageGenerator,
         qos: QualityOfService = .userInitiated,
         progressHandler: @escaping (Int) -> (),
         completionHandler: @escaping ([Result]) -> ()) {

        self.request = request
        self.frameStartIndex = frameStartIndex
        self.generator = generator
        self.completionHandler = completionHandler
        self.progressHandler = progressHandler
        super.init()
        self.qualityOfService = qos
    }

    override func cancel() {
        super.cancel()
        generator.cancelAllCGImageGeneration()
    }

    override func main() {
        guard !isCancelled else {
            completionHandler(.init(repeating: .cancelled, count: request.times.count))
            return
        }

        // Since the operation is already asynchronous, make `generateCGImagesAsynchronously`
        // synchronous within the current queue.
        let block = DispatchGroup()
        block.enter()

        // Since frame generation is strictly sequential, modifying the array from
        // different threads is safe.
        var results = [Result]()
        let times = request.times.map(NSValue.init)
        var index = frameStartIndex

        generator.generateCGImagesAsynchronously(forTimes: times) { [weak self] requestedTime, image, actualTime, status, error in
            guard let self = self else { return }

            // When the operation is cancelled, subsequent invocations might report
            // `succeeded` as images might already have been generated while the current
            // one is slowly being written to disk. Discard those images manually.
            let status = self.isCancelled ? .cancelled : status

            switch (status, image) {

            case (.cancelled, _):
                results.append(.cancelled)

            case (.succeeded, let image?):
                let fileUrl = self.write(image, for: self.request, index: index)
                results.append(fileUrl)

            default:
                results.append(.failed(error))
            }

            self.progressHandler(index)
            index += 1

            if results.count == times.count {
                self.completionHandler(results)
                block.leave()
            }
        }

        block.wait()
    }

    private func write(_ image: CGImage, for request: FrameExporter.Request, index: Int) -> Result {
        guard let directory = request.directory,
            let encodedImage = image.data(with: request.encoding) else { return .failed(nil) }

        do {
            let fileUrl = url(forFrameAt: index, in: directory, format: request.encoding.format)
            try encodedImage.write(to: fileUrl)
            return .succeeded(fileUrl)
        } catch let error {
            return .failed(error)
        }
    }

    private func url(forFrameAt index: Int, in directory: URL, format: ImageFormat) -> URL {
        let suffix = (index == 0) ? "" : "-\(index)"
        let fileName = "Frame\(suffix).\(format.fileExtension)"
        return directory.appendingPathComponent(fileName)
    }
}
