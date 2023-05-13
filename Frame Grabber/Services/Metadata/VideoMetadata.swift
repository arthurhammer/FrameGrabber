import CoreLocation
import CoreMedia
import Foundation

/// A collection of general metadata of a video asset.
struct VideoMetadata: Equatable {
    let duration: CMTime?
    let creationDate: Date?
    /// The creation date as a string if it could not be parsed as a `Date`.
    let creationDateString: String?
    /// Metadata from a video track of the asset, typically the first.
    let track: Track?
    /// Metadata from the `commonMetadata` of the asset.
    let common: Common?
}

extension VideoMetadata {
    
    /// A collection of metadata of an asset's video track (`AVAssetTrack`).
    struct Track: Equatable {
        let trackID: CMPersistentTrackID
        let naturalSize: CGSize?
        let preferredTransform: CGAffineTransform?
        let nominalFrameRate: Float?
        let estimatedDataRate: Float?
        let totalSampleDataLength: Int64?
        let formatDescriptions: [CMFormatDescription]?
    }

    /// A collection of common metadata of an asset.
    struct Common: Hashable {
        let make: String?
        let model: String?
        let software: String?
        let locationString: String?
        /// The location if it could be parsed from `locationString`.
        let location: CLLocation?
    }
}

extension VideoMetadata.Track {
    
    /// The natural size applying the preferred transform.
    ///
    /// If `preferredTransform` is `nil`, returns the natural size.
    var dimensions: CGSize? {
        guard let size = naturalSize,
              let transform = preferredTransform
        else {
            return naturalSize
        }
        
        return size.applying(transform).abs
    }
}
