import AVFoundation
import CoreMedia
import SampleTimeIndexer

/// Provides frame-accurate timing information for an asset.
class VideoTimeProvider {

    var asset: AVAsset? {
        didSet {
            guard asset != oldValue else { return }
            indexFrames()
        }
    }

    /// If true, starts asynchronously indexing the asset's frames and, when finished successfully, provides
    /// frame-accurate timing in `time(for:)`. Otherwise, cancels indexing and discards indexed frames.
    var providesFrameAccurateTiming = true {
        didSet {
            guard providesFrameAccurateTiming != oldValue else { return }
            indexFrames()
        }
    }

    private var times: SampleTimes?
    private let indexer: SampleTimeIndexer

    init(asset: AVAsset? = nil, indexer: SampleTimeIndexer = .init()) {
        self.asset = asset
        self.indexer = indexer
        indexFrames()
    }

    /// The start time of the frame closest to the requested time or, if not available, the
    /// requested time.
    ///
    /// For the receiver to provide frame-accurate times, `providesFrameAccurateTiming` must be true
    /// and the asynchronous frame indexing operation must have finished successfully.
    func samplePresentationTime(for playbackTime: CMTime) -> CMTime {
        times?.sampleTiming(for: playbackTime)?.presentationTimeStamp ?? playbackTime
    }

    private func resetIndexing() {
        indexer.cancel()
        times = nil
    }

    private func indexFrames() {
        resetIndexing()

        guard providesFrameAccurateTiming,
              let asset = asset,
              times == nil else { return }

        indexer.indexSamples(for: asset) { [weak self] result in
            switch result {
            case .failure:
                break  // Ignore silently for now.
            case .success(let indexedFrames):
                DispatchQueue.main.async {
                    self?.times = indexedFrames
                }
            }
        }
    }
}
