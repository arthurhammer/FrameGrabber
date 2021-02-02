import AVFoundation
import CoreLocation

private let assetKeys = [
    #keyPath(AVAsset.duration),
    #keyPath(AVAsset.creationDate),
    #keyPath(AVAsset.tracks),
    #keyPath(AVAsset.commonMetadata),
]

private let commonMetadataKeys = [
    AVMetadataIdentifier.commonIdentifierMake,
    AVMetadataIdentifier.commonIdentifierModel,
    AVMetadataIdentifier.commonIdentifierSoftware,
    AVMetadataIdentifier.commonIdentifierLocation
]

// MARK: - Asset

extension AVAsset {
        
    /// In accordance with `AVAsynchronousKeyValueLoading`, asynchronously loads some basic, fixed
    /// set of metadata about the asset.
    ///
    /// The metadata is loaded on best-effort basis as optional values. No detailed error
    /// information is provided in case a value could not be loaded. If it couldn't, it might for
    /// example be that the key is not present in the asset, it is present but it could not be read,
    /// or any other potential failure.
    ///
    /// The completion handler is called on an arbitrary queue. The asset maintains a strong
    /// reference to itself until the handler is called.
    func loadMetadata(completion: @escaping (VideoMetadata) -> ()) {
        loadValuesAsynchronously(forKeys: assetKeys) {
            let assetMetadata = self.loadAssetMetadata()
            let commonMetadata = self.loadCommonMetadata()
            
            self.loadTrackMetadata() { trackMetadata in
                let completeMetadata = VideoMetadata(
                    asset: assetMetadata,
                    track: trackMetadata,
                    common: commonMetadata
                )
                
                completion(completeMetadata)
            }
        }
    }
    
    /// The `duration` and `creationDate` keys should be loaded before calling this.
    private func loadAssetMetadata() -> VideoAssetMetadata {
        let durationKey = #keyPath(AVAsset.duration)
        let creationDateKey = #keyPath(AVAsset.creationDate)
        
        assert(isLoadingCompleted(durationKey))
        assert(isLoadingCompleted(creationDateKey))

        let duration = ifLoaded(durationKey) { $0.duration }
        let creationDate = ifLoaded(creationDateKey) { $0.creationDate } ?? nil
     
        creationDate?._assertIsLoadingCompleted()
                
        return VideoAssetMetadata(
            duration: duration,
            creationDateString: creationDate?.stringValue,
            creationDate: creationDate?.dateValue
        )
    }
    
    /// The `tracks` key should be loaded before calling this.
    private func loadTrackMetadata(completion: @escaping (VideoTrackMetadata?) -> ()) {
        let tracksKey = #keyPath(AVAsset.tracks)
        assert(isLoadingCompleted(tracksKey))
        
        guard isLoaded(tracksKey),
              let sourceTrack = tracks(withMediaType: .video).first else {
            completion(nil)
            return
        }
        
        sourceTrack.loadMetadata(completion: completion)
    }
    
    /// The `commonMetadata` key should be loaded before calling this.
    private func loadCommonMetadata() -> VideoCommonMetadata? {
        let commonMetadataKey = #keyPath(AVAsset.commonMetadata)
        assert(isLoadingCompleted(commonMetadataKey))
        
        guard isLoaded(commonMetadataKey) else { return nil }
        
        commonMetadataKeys
            .compactMap(commonMetadataItem)
            .forEach { $0._assertIsLoadingCompleted() }
                
        let locationString = commonMetadataItem(for: .commonIdentifierLocation)?.stringValue
        let location = locationString.flatMap(ISO6709LocationParser().location)
        
        return VideoCommonMetadata(
            make: commonMetadataItem(for: .commonIdentifierMake)?.stringValue,
            model: commonMetadataItem(for: .commonIdentifierModel)?.stringValue,
            software: commonMetadataItem(for: .commonIdentifierSoftware)?.stringValue,
            locationString: locationString,
            location: location
        )
    }
    
    /// The `commonMetadata` key should be loaded before calling this.
    private func commonMetadataItem(for identifier: AVMetadataIdentifier) -> AVMetadataItem? {
        AVMetadataItem.metadataItems(from: commonMetadata, filteredByIdentifier: identifier).first
    }
}
