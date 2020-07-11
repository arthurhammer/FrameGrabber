import AVFoundation
import CoreMedia
import FrameIndexer

class VideoTimeProvider {

    var asset: AVAsset? {
        didSet {
            guard asset != oldValue else { return }
            indexFrames()
        }
    }

    /// If true, starts indexing asset's frames and, when finished successfully, provides frame-accurate timing
    /// in `time(for:)`. If false, cancels indexing and simply returns the given target time in `time(for:)`.
    var providesFrameAccurateTiming = true {
        didSet {
            guard providesFrameAccurateTiming != oldValue else { return }
            indexFrames()
        }
    }

    private var indexedFrames: IndexedFrames?
    private let indexer: FrameIndexer

    init(asset: AVAsset? = nil, indexer: FrameIndexer = .init()) {
        self.asset = asset
        self.indexer = indexer
        indexFrames()
    }

    /// If `providesFrameAccurateTiming` is true and frames have finished indexing successfully, returns the time of
    /// the video frame closest to the target time. Otherwise, the target time.
    func time(for target: CMTime) -> CMTime {
        indexedFrames?.frame(closestTo: target) ?? target
    }

    private func resetIndexing() {
        indexer.cancel()
        indexedFrames = nil
    }

    private func indexFrames() {
        resetIndexing()

        guard providesFrameAccurateTiming,
              let asset = asset,
              indexedFrames == nil else { return }

        indexer.indexFrames(for: asset) { [weak self] result in
            switch result {
            case .failure:
                break  // Ignore silently for now.
            case .success(let indexedFrames):
                DispatchQueue.main.async {
                    self?.indexedFrames = indexedFrames
                }
            }
        }
    }
}
