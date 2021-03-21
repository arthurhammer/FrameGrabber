import Photos

/// A type-erasing album with static content.
public struct Album: AlbumProtocol {
    public let assetCollection: PHAssetCollection
    public let title: String?
    public let count: Int
    public let keyAsset: PHAsset?
}

extension Album {

    /// Initializes the album with the given album.
    ///
    /// - Note: Properties are assigned and not forwarded on each access.
    public init<A>(album: A) where A: AlbumProtocol {
        self.assetCollection = album.assetCollection
        self.title = album.title
        self.count = album.count
        self.keyAsset = album.keyAsset
    }
}
