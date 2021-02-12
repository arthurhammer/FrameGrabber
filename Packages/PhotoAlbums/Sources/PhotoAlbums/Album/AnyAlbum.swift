import Photos

/// A type-erasing album with static content.
public struct AnyAlbum: Album {
    public let assetCollection: PHAssetCollection
    public let title: String?
    public let count: Int
    public let keyAsset: PHAsset?
}

extension AnyAlbum {

    /// Initializes the album with the given album.
    ///
    /// - Note: Properties are assigned and not forwarded on each access.
    public init<A>(album: A) where A: Album {
        self.assetCollection = album.assetCollection
        self.title = album.title
        self.count = album.count
        self.keyAsset = album.keyAsset
    }
}
