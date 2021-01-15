import AVFoundation

/// An operation that indexes a video's samples to provide accurate timing information for each
/// sample.
class SampleTimeIndexOperation: Operation {

    typealias Result = Swift.Result<[CMSampleTimingInfo], SampleTimeIndexError>

    // These property are accessed from multiple threads (`init`, `main`, `completionBlock`).
    // However, access is never concurrent, only strictly sequentially. Skip locking.
    private let asset: AVAsset
    private let sourceTrack: AVAssetTrack?
    private let sampleLimit: Int
    private var result: Result

    init(asset: AVAsset, sampleLimit: Int = .max, completionHandler: @escaping (Result) -> Void) {
        self.asset = asset
        // todo: AVAsynchronousKeyValueLoading
        self.sourceTrack = asset.tracks(withMediaType: .video).first
        self.sampleLimit = sampleLimit
        self.result = .failure(.cancelled)  // In case task is cancelled before started.

        super.init()

        completionBlock = { [weak self] in
            if let self = self {
                completionHandler(self.isCancelled ? .failure(.cancelled) : self.result)
            } else {
                completionHandler(.failure(.cancelled))
            }
        }
    }

    override func main() {
        guard !isCancelled else { return }

        result = preparedReader(for: asset)
            .flatMap(readSamples)
            .flatMap(validatedAndSorted)
    }
}

// MARK: - Private

private extension SampleTimeIndexOperation {
    
    typealias ReaderConfiguration = (AVAssetReader, AVAssetReaderTrackOutput)

    /// Reads all samples' timing infos from the asset, periodically checking if the receiver has
    /// been cancelled and aborting in that case.
    func readSamples(using configuration: ReaderConfiguration) -> Result {
        let (reader, output) = configuration
        
        defer { reader.cancelReading() }

        var buffer: CMSampleBuffer?
        var timings = [CMSampleTimingInfo]()

        repeat {
            guard !isCancelled else {
                return .failure(.cancelled)
            }

            buffer = output.copyNextSampleBuffer()

            do {
                if let bufferTimings = try buffer?.individualOutputSampleTimingInfos() {
                    timings.append(contentsOf: bufferTimings)
                }
            } catch {
                return .failure(.readingFailed(error))
            }

            if timings.count > sampleLimit {
                return .failure(.sampleLimitReached)
            }

        } while buffer != nil

        guard reader.status == .completed else {
            return .failure(.readingFailed(reader.error))
        }

        return .success(timings)
    }

    /// The timing infos sorted by their presentation time if all times are valid.
    func validatedAndSorted(timings: [CMSampleTimingInfo]) -> Result {
        if !timings.allSatisfy({ $0.presentationTimeStamp.isNumeric }) {
            return .failure(.readingFailed(nil))
        }

        let sorted = timings.sorted {
            $0.presentationTimeStamp < $1.presentationTimeStamp
        }
        
        return .success(sorted)
    }
        
    /// On success, a reader and reader output ready to read the track's samples.
    func preparedReader(for asset: AVAsset) -> Swift.Result<ReaderConfiguration, SampleTimeIndexError> {
        guard let track = sourceTrack else {
            return .failure(.invalidVideo)
        }

        let reader: AVAssetReader
        let output = AVAssetReaderTrackOutput(track: track, outputSettings: nil)
        output.alwaysCopiesSampleData = false

        do {
            reader = try AVAssetReader(asset: asset)
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
