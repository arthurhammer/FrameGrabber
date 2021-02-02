import CoreMedia

/// Metadata read directly from an `AVAsset` instance.
struct VideoAssetMetadata: Equatable {
    let duration: CMTime?
    /// The creation date as a string if it could not be parsed as a `Date`.
    let creationDateString: String?
    let creationDate: Date?
}
