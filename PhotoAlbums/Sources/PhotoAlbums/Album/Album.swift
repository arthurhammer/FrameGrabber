import Photos

/// A type that represents a PhotoKit album.
public protocol Album: Identifiable, Hashable {
    var assetCollection: PHAssetCollection { get }
    var id: String { get }
    var title: String? { get }
    var count: Int { get }
    /// The asset that provides the album's thumbnail.
    var keyAsset: PHAsset? { get }
}

extension Album {

    public var id: String {
        assetCollection.localIdentifier
    }

    public var title: String? {
        assetCollection.localizedTitle
    }

    public var isEmpty: Bool {
        count == 0
    }
}
