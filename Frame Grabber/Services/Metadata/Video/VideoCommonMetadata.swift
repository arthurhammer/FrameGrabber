import CoreLocation

/// Metadata read from the common metadata items (`AVMetadataItem`) of an asset.
struct VideoCommonMetadata: Hashable {
    let make: String?
    let model: String?
    let software: String?
    let locationString: String?
    /// The location if it could be parsed from `locationString`.
    let location: CLLocation?
}
