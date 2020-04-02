import Photos

extension AlbumsDataSource {

    public struct SmartAlbumConfiguration {
        public let types: [PHAssetCollectionSubtype]
        public let assetFetchOptions: PHFetchOptions

        public init(types: [PHAssetCollectionSubtype] = [.smartAlbumUserLibrary, .smartAlbumFavorites],
                    assetFetchOptions: PHFetchOptions = .assets(forAlbumType: .smartAlbum)) {

            self.types = types
            self.assetFetchOptions = assetFetchOptions
        }
    }

    public struct UserAlbumConfiguration {
        public let albumFetchOptions: PHFetchOptions
        public let assetFetchOptions: PHFetchOptions

        public init(albumFetchOptions: PHFetchOptions = .userAlbums(),
                    assetFetchOptions: PHFetchOptions = .assets(forAlbumType: .smartAlbum)) {

            self.albumFetchOptions = albumFetchOptions
            self.assetFetchOptions = assetFetchOptions
        }
    }
}

extension PHFetchOptions {

    /// Default fetch options for user albums, i.e. sorted by title.
    public static func userAlbums() -> PHFetchOptions {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "localizedTitle", ascending: true)]
        return options
    }

    /// Default fetch options for assets depending on album type.
    ///
    /// For smart albums, assets are sorted by creation date. For user albums, assets are unsorted,
    /// i.e. they follow the user's custom sort order.
    public static func assets(forAlbumType albumType: PHAssetCollectionType) -> PHFetchOptions {
        let options = PHFetchOptions()
        options.sortDescriptors = albumType.sortDescriptors
        options.includeAssetSourceTypes = [.typeUserLibrary, .typeiTunesSynced, .typeCloudShared]
        return options
    }
}

extension PHAssetCollectionType {

    fileprivate var sortDescriptors: [NSSortDescriptor]? {
        switch self {
        case .smartAlbum: return [NSSortDescriptor(key: "creationDate", ascending: false)]
        case .album: return nil
        default: return nil
        }
    }
}
