import Photos

extension AlbumsDataSource {

    /// The kind of smart albums and the kind of assets to fetch.
    ///
    /// The type of assets specified by `assetFetchOptions` only affect the `count` and `keyAsset`
    /// properties of the returned photo album  data. For example, if you specify options to only
    /// fetch favorited Live Photos, each album contains the exact count of how many such favorited
    /// Live Photos it contains and the key asset will be the most recent one of this kind.
    ///
    /// To determine this information, the data source fetches all albums and queries it for this
    /// information in the background. This is typically a slow process. If you intend to work with
    /// the full, unfiltered photo library, you should work with `PHAssetCollection` directly.
    ///
    /// The data source always returns all specified smart albums, even if they are empty for the
    /// specified asset types.
    public struct SmartAlbumConfiguration {
        
        public let types: [PHAssetCollectionSubtype]
        public let assetFetchOptions: PHFetchOptions?
        
        /// - Parameters:
        ///   - types: The types of smart albums to fetch. Must be one of the smart album subtypes.
        ///   - assetFetchOptions: The types of assets to fetch. By default `nil`, i.e. sorted by
        ///     date added, in chronological order.
        public init(
            types: [PHAssetCollectionSubtype] = [.smartAlbumUserLibrary],
            assetFetchOptions: PHFetchOptions? = nil
        ) {
            self.types = types
            self.assetFetchOptions = assetFetchOptions
        }
    }

    /// The kind of user albums and the kind of assets to fetch.
    ///
    /// See `SmartAlbumConfiguration` for details. In contrast to smart albums, however, the data
    /// source returns only albums that are not empty for the specified asset types.
    public struct UserAlbumConfiguration {
        
        public let albumFetchOptions: PHFetchOptions?
        public let assetFetchOptions: PHFetchOptions?

        /// - Parameters:
        ///   - types: The types of user albums to fetch.
        ///   - assetFetchOptions: The types of assets to fetch. By default `nil`, i.e. sorted by
        ///     the user's custom order in the photo library.
        public init(
            albumFetchOptions: PHFetchOptions? = nil,
            assetFetchOptions: PHFetchOptions? = nil
        ) {
            self.albumFetchOptions = albumFetchOptions
            self.assetFetchOptions = assetFetchOptions
        }
    }
}
