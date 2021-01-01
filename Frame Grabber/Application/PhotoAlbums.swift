import PhotoAlbums
import Photos

// App-specific albums configuration.
extension AlbumsDataSource {

    static let smartAlbumTypes: [PHAssetCollectionSubtype] = [
        .smartAlbumUserLibrary,
        .smartAlbumFavorites,
        .smartAlbumTimelapses,
        .smartAlbumSlomoVideos
    ]

    static func `default`() -> AlbumsDataSource {
        let smartAlbumConfig = SmartAlbumConfiguration(
            types: AlbumsDataSource.smartAlbumTypes,
            assetFetchOptions: .assets(forAlbumType: .smartAlbum, videoFilter: .all)
        )

        let userAlbumConfig = UserAlbumConfiguration(
            albumFetchOptions: .userAlbums(),
            assetFetchOptions: .assets(forAlbumType: .album, videoFilter: .all)
        )

        return AlbumsDataSource(
            smartAlbumConfig: smartAlbumConfig,
            userAlbumConfig: userAlbumConfig
        )
    }

    static func fetchInitialAssetCollection() -> PHAssetCollection? {
        guard let type = smartAlbumTypes.first else { return nil }
        
        return PHAssetCollection.fetchAssetCollections(
            with: .smartAlbum,
            subtype: type,
            options: nil
        ).firstObject
    }
}

extension PHFetchOptions {

    static func assets(forAlbumType albumType: PHAssetCollectionType, videoFilter: VideoTypesFilter) -> PHFetchOptions {
        let options = PHFetchOptions.assets(forAlbumType: albumType)
        options.predicate = videoFilter.photoLibraryFetchPredicate
        return options
    }
}
