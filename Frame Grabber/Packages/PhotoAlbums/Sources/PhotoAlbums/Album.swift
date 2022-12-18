import Photos

/// A `PhotoKit` photo album.
public struct Album: AlbumProtocol {
    
    public let assetCollection: PHAssetCollection
    public let title: String?
    public let count: Int
    public let keyAsset: PHAsset?
    
    public init(assetCollection: PHAssetCollection, title: String?, count: Int, keyAsset: PHAsset?) {
        self.assetCollection = assetCollection
        self.title = title
        self.count = count
        self.keyAsset = keyAsset
    }
}

extension Album {

    /// Initializes the album with the given album.
    public init(album: any AlbumProtocol) {
        self.assetCollection = album.assetCollection
        self.title = album.title
        self.count = album.count
        self.keyAsset = album.keyAsset
    }
}
