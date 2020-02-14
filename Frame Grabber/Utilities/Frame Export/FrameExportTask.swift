import AVFoundation

class FrameExportTask: Operation {

    typealias Request = FrameExport.Request
    typealias Status = FrameExport.Status

    let request: Request
    let frameStartIndex: Int
    let generator: AVAssetImageGenerator
    let frameProcessedHandler: (Int, Status) -> ()

    /// - Parameter frameStartIndex: If the task represents a chunk of a larger task, the
    ///   index describes the index of generated frames relative to the larger task. The
    ///   value is also used to generate file names for exported images.
    /// - Parameter frameProcessedHandler: Called on an arbitrary queue.
    init(generator: AVAssetImageGenerator,
         request: Request,
         frameStartIndex: Int = 0,
         frameProcessedHandler: @escaping (Int, Status) -> ()) {

        self.generator = generator
        self.request = request
        self.frameStartIndex = frameStartIndex
        self.frameProcessedHandler = frameProcessedHandler

        super.init()

        self.qualityOfService = .userInitiated
    }

    override func cancel() {
        super.cancel()
        generator.cancelAllCGImageGeneration()
    }

    override func main() {
        guard !isCancelled else {
            return
        }

        // Since the operation is already asynchronous, make `generateCGImagesAsynchronously`
        // synchronous within the current queue.
        let block = DispatchGroup()
        block.enter()

        // Can be safely modified from the generator's callbacks' threads as they are
        // strictly sequential.
        let times = request.times.map(NSValue.init)
        var countProcessed = 0

        generator.generateCGImagesAsynchronously(forTimes: times) { [weak self] _, image, _, status, error in
            guard let self = self else { return }

            let frameIndex = self.frameStartIndex + countProcessed

            // When the operation is cancelled, subsequent AVAssetImageGenerator callbacks
            // might report `succeeded` as images might already have been generated while
            // the current one is slowly being written to disk. Consider them cancelled too.
            switch (self.isCancelled, status, image) {

            case (true, _, _), (_, .cancelled, _):
                self.frameProcessedHandler(frameIndex, .cancelled)

            case (_, .succeeded, let image?):
                let writeResult = self.write(image, for: self.request, index: frameIndex)
                self.frameProcessedHandler(frameIndex, writeResult)

            default:
                self.frameProcessedHandler(frameIndex, .failed(error))
            }

            countProcessed += 1

            if countProcessed == times.count {
                block.leave()
            }
        }

        block.wait()
    }

    private func write(_ image: CGImage, for request: Request, index: Int) -> Status {
        guard let directory = request.directory,
            let encodedImage = image.data(with: request.encoding) else { return .failed(nil) }

        do {
            let fileUrl = url(forFrameAt: index, in: directory, format: request.encoding.format)
            try encodedImage.write(to: fileUrl)
            return .succeeded([fileUrl])
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
