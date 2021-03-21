import Photos

/// The kind of smart albums and the kind of assets to fetch for each album.
public struct SmartAlbumsFetchOptions {

    public let types: [PHAssetCollectionSubtype]
    public let assetOptions: PHFetchOptions?
    public let includesEmptyAlbums: Bool
    
    /// - Parameters:
    ///   - types: The types of smart albums to fetch. The default is `defaultSmartAlbumTypes`.
    ///   - assetOptions: The types of assets to fetch for each album. The default is `nil` which
    ///     returns assets chronologically by date added.
    ///   - includesEmpty: Whether to include albums that don't contain any of the specified asset
    ///     types. The default is `true`.
    ///
    /// - Note: The returned key asset is always the last of the fetched ones. If no sort
    ///   order is specified, this corresponds to the most recently added asset. However, if a sort
    ///   order is specified, it will still be the last one according to that order.
    public init(
        types: [PHAssetCollectionSubtype] = defaultSmartAlbumTypes,
        assetOptions: PHFetchOptions? = nil,
        includesEmptyAlbums: Bool = true
    ) {
        self.types = types
        self.assetOptions = assetOptions
        self.includesEmptyAlbums = includesEmptyAlbums
    }
    
    /// The default selection of smart albums to fetch.
    public static let defaultSmartAlbumTypes: [PHAssetCollectionSubtype] = [
        .smartAlbumUserLibrary,
        .smartAlbumFavorites,
        .smartAlbumVideos,
        .smartAlbumLivePhotos,
        .smartAlbumSelfPortraits,
        .smartAlbumScreenshots
    ]
}
