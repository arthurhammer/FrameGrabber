import CoreGraphics
import CoreLocation
import Photos

/// Metadata read from an asset in the photo library.
struct PhotoLibraryMetadata: Equatable {
    /// The local identifier ot the `PHAsset`.
    let assetID: String
    let creationDate: Date?
    let location: CLLocation?
    let dimensions: CGSize
    let duration: Double
    let type: PHAssetMediaType
    let subtypes: PHAssetMediaSubtype
}

extension PhotoLibraryMetadata {
    init(asset: PHAsset) {
        self.assetID = asset.localIdentifier
        self.creationDate = asset.creationDate
        self.location = asset.location
        self.type = asset.mediaType
        self.subtypes = asset.mediaSubtypes
        self.dimensions = asset.dimensions
        self.duration = asset.duration
    }
}
