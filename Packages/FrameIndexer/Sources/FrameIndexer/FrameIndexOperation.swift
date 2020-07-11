import AVFoundation

/// An operation that indexes frames in a video.
///
/// If successful, the result is a sorted list of frame presentation time stamps.
class FrameIndexOperation: Operation {

    typealias IndexResult = Result<[CMTime], FrameIndexError>

    private let video: AVAsset
    private var result: IndexResult
    private let frameLimit: Int

    /// - Parameters:
    ///   - video: The video to index.
    ///   - frameLimit: The maximum number of frames to read.
    ///   - completionHandler: Called from an arbitrary execution context. On success,
    ///     returns the frame output presentation time stamps of the video.
    init(video: AVAsset, frameLimit: Int = .max, completionHandler: @escaping (IndexResult) -> Void) {
        self.video = video
        self.frameLimit = frameLimit
        result = .failure(.cancelled)

        super.init()

        completionBlock = { [weak self] in
            completionHandler(self?.result ?? .failure(.cancelled))
        }
    }

    override func main() {
        guard !isCancelled else { return }

        let result = preparedReader(for: video)
            .flatMap(readSamples)
            .flatMap(validated)

        self.result = isCancelled ? .failure(.cancelled) : result
    }
}

// MARK: - Private

private extension FrameIndexOperation {

    /// Reads all samples in the video, periodically checking if the receiver has been
    /// cancelled and aborting in that case.
    /// - Returns: A list of presentation time stamps if successful.
    func readSamples(using readerConfiguration: (AVAssetReader, AVAssetReaderTrackOutput)) -> IndexResult {
        let (reader, output) = readerConfiguration

        var buffer: CMSampleBuffer?
        var frameTimes = [CMTime]()

        repeat {
            guard !isCancelled else {
                reader.cancelReading()
                return .failure(.cancelled)
            }

            buffer = output.copyNextSampleBuffer()

            if let buffer = buffer {
                do {
                    let times = try buffer.outputSamplePresentationTimeStamps()
                    frameTimes.append(contentsOf: times)
                } catch {
                    return .failure(.readingFailed(error))
                }
            }

            if frameTimes.count > frameLimit {
                return .failure(.frameLimitReached)
            }

        } while buffer != nil

        if reader.status != .completed {
            return .failure(.readingFailed(reader.error))
        }

        return .success(frameTimes)
    }

    /// `frameTimes` sorted if all times are valid, otherwise an error.
    func validated(frameTimes: [CMTime]) -> IndexResult {
        if !frameTimes.allSatisfy({ $0.isNumeric }) {
            return .failure(.readingFailed(nil))
        }

        return .success(frameTimes.sorted())
    }

    /// On success, a reader and reader output ready to read samples.
    func preparedReader(for video: AVAsset) -> Result<(AVAssetReader, AVAssetReaderTrackOutput), FrameIndexError> {
        guard let videoTrack = video.tracks(withMediaType: .video).first else {
            return .failure(.invalidVideo)
        }

        let reader: AVAssetReader
        let output = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: nil)
        output.alwaysCopiesSampleData = false

        do {
            reader = try AVAssetReader(asset: video)
        } catch {
            return .failure(.readingFailed(error))
        }

        guard reader.canAdd(output) else {
            return .failure(.readingFailed(nil))
        }

        reader.add(output)

        guard reader.startReading() else {
            return .failure(.readingFailed(reader.error))
        }

        return .success((reader, output))
    }
}
