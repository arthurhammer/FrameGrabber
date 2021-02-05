import AVFoundation

private let trackKeys = [
    #keyPath(AVAssetTrack.trackID),
    #keyPath(AVAssetTrack.naturalSize),
    #keyPath(AVAssetTrack.preferredTransform),
    #keyPath(AVAssetTrack.nominalFrameRate),
    #keyPath(AVAssetTrack.estimatedDataRate),
    #keyPath(AVAssetTrack.totalSampleDataLength),
    #keyPath(AVAssetTrack.formatDescriptions),
]

extension AVAssetTrack {

    /// Same assumptions as in `AVAsset.loadMetadata`.
    func loadMetadata(completion: @escaping (VideoTrackMetadata) -> Void) {
        loadValuesAsynchronously(forKeys: trackKeys) {
            completion(self.loadedTrackMetadata())
        }
    }
    
    /// All keys in `trackKeys` should be loaded before calling this.
    private func loadedTrackMetadata() -> VideoTrackMetadata {
        trackKeys.forEach { assert(isLoadingCompleted($0)) }
        
        let naturalSize = ifLoaded(#keyPath(AVAssetTrack.naturalSize)) {
            $0.naturalSize
        }
        
        let preferredTransform = ifLoaded(#keyPath(AVAssetTrack.preferredTransform)) {
            $0.preferredTransform
        }
        
        let nominalFrameRate = ifLoaded(#keyPath(AVAssetTrack.nominalFrameRate)) {
            $0.nominalFrameRate
        }
        
        let estimatedDataRate = ifLoaded(#keyPath(AVAssetTrack.estimatedDataRate)) {
            $0.estimatedDataRate
        }
        
        let totalSampleDataLength = ifLoaded(#keyPath(AVAssetTrack.totalSampleDataLength)) {
            $0.totalSampleDataLength
        }
        
        let formatDescriptions = ifLoaded(#keyPath(AVAssetTrack.formatDescriptions)) {
            $0.formatDescriptions as! [CMFormatDescription]
        }
        
        return VideoTrackMetadata(
            trackID: trackID,
            naturalSize: naturalSize,
            preferredTransform: preferredTransform,
            nominalFrameRate: nominalFrameRate,
            estimatedDataRate: estimatedDataRate,
            totalSampleDataLength: totalSampleDataLength,
            formatDescriptions: formatDescriptions
        )
    }
}

