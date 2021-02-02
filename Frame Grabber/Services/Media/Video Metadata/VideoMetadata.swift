/// The set of metadata of an `AVAsset` video.
struct VideoMetadata: Equatable {
    
    /// Metadata loaded from the asset directly.
    let asset: VideoAssetMetadata
    
    /// Metadata loaded from a video track of the asset (typically the first one).
    let track: VideoTrackMetadata?
    
    /// Metadata loaded from the common metadata of the asset.
    let common: VideoCommonMetadata?
}
