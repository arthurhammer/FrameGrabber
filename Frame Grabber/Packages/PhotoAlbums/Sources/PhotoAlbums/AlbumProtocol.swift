import Photos

/// A type that represents a `PhotoKit` photo album.
public protocol AlbumProtocol: Identifiable, Hashable {
    
    /// The photo album.
    var assetCollection: PHAssetCollection { get }
    
    /// The album's identifier, used to track changes.
    var id: String { get }
    
    /// The album's title.
    var title: String? { get }
    
    /// The number of assets in the album.
    var count: Int { get }
    
    /// The asset that provides the album's thumbnail.
    var keyAsset: PHAsset? { get }
}

// MARK: - Default Implementation

extension AlbumProtocol {

    public var id: String {
        assetCollection.localIdentifier
    }

    public var title: String? {
        assetCollection.localizedTitle
    }
    
    public var count: Int {
        assetCollection.estimatedAssetCount
    }

    public var isEmpty: Bool {
        count == 0
    }
}
