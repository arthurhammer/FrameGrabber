import CoreMedia
import CoreGraphics

/// Metadata read from an asset's video track (`AVAssetTrack`).
struct VideoTrackMetadata: Equatable {
    /// The id of the source track.
    let trackID: CMPersistentTrackID
    let naturalSize: CGSize?
    let preferredTransform: CGAffineTransform?
    let nominalFrameRate: Float?
    let estimatedDataRate: Float?
    let totalSampleDataLength: Int64?
    let formatDescriptions: [CMFormatDescription]?
}

extension VideoTrackMetadata {
    
    /// The natural size applying the preferred transform.
    ///
    /// If `preferredTransform` is `nil`, returns the natural size.
    var dimensions: CGSize? {
        guard let size = naturalSize,
              let transform = preferredTransform else { return naturalSize }
        
        return size.applying(transform).abs
    }
}
