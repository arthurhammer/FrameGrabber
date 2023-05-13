import Photos

/// The kind of user albums and the kind of assets to fetch for each album.
public struct UserAlbumsFetchOptions {
    
    public let albumOptions: PHFetchOptions?
    public let assetOptions: PHFetchOptions?
    public let includesEmptyAlbums: Bool

    /// - Parameters:
    ///   - types: The types of user albums to fetch. The default are options that return albums
    ///     sorted by title.
    ///   - assetOptions: The types of assets to fetch for each album. The default is `nil` which
    ///     returns assets in the user's custom order in the photo library.
    ///   - includesEmpty: Whether to include albums that don't contain any of the specified asset
    ///     types. The default is `false`.
    ///
    /// - Note: The returned key asset is the first of the fetched assets.
    public init(
        albumOptions: PHFetchOptions? = defaultAlbumOptions(),
        assetOptions: PHFetchOptions? = nil,
        includesEmptyAlbums: Bool = false
    ) {
        self.albumOptions = albumOptions
        self.assetOptions = assetOptions
        self.includesEmptyAlbums = includesEmptyAlbums
    }
    
    /// Default fetch options for user albums, i.e. albums sorted by title.
    public static func defaultAlbumOptions() -> PHFetchOptions {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "localizedTitle", ascending: true)]
        return options
    }
}
