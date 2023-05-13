import AVFoundation

/// An operation that indexes a video's samples to provide accurate timing information for each
/// sample.
class SampleTimeIndexOperation: Operation {

    typealias Result<Success> = Swift.Result<Success, SampleTimeIndexError>

    // These property are accessed from multiple threads (`init`, `main`, `completionBlock`).
    // However, access is never concurrent, only strictly sequentially. Skip locking.
    private let asset: AVAsset
    private let sourceTrack: AVAssetTrack?
    private let naturalTimeScale: CMTimeScale?
    private let sampleLimit: Int
    private var result: Result<SampleTimes>

    init(
        asset: AVAsset,
        sampleLimit: Int = .max,
        completionHandler: @escaping (Result<SampleTimes>
    ) -> Void) {
        
        self.asset = asset
        self.sampleLimit = sampleLimit
        self.result = .failure(.cancelled)  // In case task is cancelled before started.
        
        // TODO: Use `AVAsynchronousKeyValueLoading` for accessing the asset's tracks and the
        // track's timescale.
        self.sourceTrack = asset.tracks(withMediaType: .video).first
        self.naturalTimeScale = self.sourceTrack?.naturalTimeScale

        super.init()

        completionBlock = { [weak self] in
            if let self {
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
        
    /// The timing infos sorted by their presentation time.
    func validatedAndSorted(timings: [CMSampleTimingInfo]) -> Result<SampleTimes> {
        guard let track = sourceTrack else {
            return .failure(.invalidVideo)
        }
        
        let timings = timings.sorted {
            $0.presentationTimeStamp < $1.presentationTimeStamp
        }
        
        let result = SampleTimes(
            values: timings,
            trackTimeScale: track.naturalTimeScale,
            trackID: track.trackID
        )
        
        return .success(result)
    }

    /// Reads all samples' timing infos from the asset, periodically checking if the receiver has
    /// been cancelled and aborting in that case.
    func readSamples(using configuration: ReaderConfiguration) -> Result<[CMSampleTimingInfo]> {
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
                return .failure(.init(underlying: error))
            }

            if timings.count > sampleLimit {
                return .failure(.sampleLimitReached)
            }

        } while buffer != nil

        guard reader.status == .completed else {
            return .failure(.init(underlying: reader.error))
        }

        return .success(timings)
    }
        
    /// On success, a reader and reader output ready to read the track's samples.
    func preparedReader(for asset: AVAsset) -> Result<ReaderConfiguration> {
        guard let track = sourceTrack else {
            return .failure(.invalidVideo)
        }

        let reader: AVAssetReader
        let output = AVAssetReaderTrackOutput(track: track, outputSettings: nil)
        output.alwaysCopiesSampleData = false

        do {
            reader = try AVAssetReader(asset: asset)
        } catch {
            return .failure(.init(underlying: error))
        }

        guard reader.canAdd(output) else {
            return .failure(.init(underlying: nil))
        }

        reader.add(output)

        guard reader.startReading() else {
            return .failure(.init(underlying: reader.error))
        }

        return .success((reader, output))
    }
}
