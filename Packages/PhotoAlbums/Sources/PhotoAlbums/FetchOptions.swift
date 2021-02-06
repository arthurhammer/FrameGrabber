import Photos

/// The kind of smart albums and the kind of assets to fetch.
///
/// With the options you specify to fetch only albums that contain specific assets, e.g. only albums
/// that contain videos. The data source returns `PhotoAlbums` that contain an exact count and a key
/// asset for the specified asset types. In addition, the data source can include or exclude albums
/// that don't contain any of the specified assets.
///
/// To determine this information, the data source fetches all albums **and** their contents in the
/// background. This is typically a slow process. If you intend to work with the full unfiltered
/// photo library, working with `PHAssetCollection` directly is much more performant.
public struct SmartAlbumsOptions {
    
    public let types: [PHAssetCollectionSubtype]
    public let assetOptions: PHFetchOptions?
    public let includesEmpty: Bool
    
    /// - Parameters:
    ///   - types: The types of smart albums to fetch. Must be one of the smart album subtypes.
    ///   - assetOptions: The types of assets to fetch. By default `nil`, i.e. sorted by
    ///     date added, in chronological order.
    ///   - includesEmpty: Whether to include albums that don't contain any of the specified asset
    ///     types. The default is `true`.
    public init(
        types: [PHAssetCollectionSubtype] = [.smartAlbumUserLibrary],
        assetOptions: PHFetchOptions? = nil,
        includesEmpty: Bool = true
    ) {
        self.types = types
        self.assetOptions = assetOptions
        self.includesEmpty = includesEmpty
    }
}

/// The kind of user albums and the kind of assets to fetch. See `SmartAlbumOptions` for details.
public struct UserAlbumsOptions {
    
    public let albumOptions: PHFetchOptions?
    public let assetOptions: PHFetchOptions?
    public let includesEmpty: Bool

    /// - Parameters:
    ///   - types: The types of user albums to fetch.
    ///   - assetOptions: The types of assets to fetch. By default `nil`, i.e. sorted by
    ///     the user's custom order in the photo library.
    ///   - includesEmpty: Whether to include albums that don't contain any of the specified asset
    ///     types. The default is `false`.
    public init(
        albumOptions: PHFetchOptions? = nil,
        assetOptions: PHFetchOptions? = nil,
        includesEmpty: Bool = false
    ) {
        self.albumOptions = albumOptions
        self.assetOptions = assetOptions
        self.includesEmpty = includesEmpty
    }
}
