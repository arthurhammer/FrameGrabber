import CoreMedia
import Foundation

/// The set of metadata of an `AVAsset` video.
struct VideoMetadata: Equatable {

    let duration: CMTime?
    
    let creationDate: Date?
    
    /// The creation date as a string if it could not be parsed as a `Date`.
    let creationDateString: String?
    
    /// Metadata from a video track of the asset, typically the first.
    let track: VideoTrackMetadata?
    
    /// Metadata from the `commonMetadata` of the asset.
    let common: VideoCommonMetadata?
}
