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
            assetFetchOptions: .assets(forAlbumType: .smartAlbum, videoType: .any)
        )

        let userAlbumConfig = UserAlbumConfiguration(
            albumFetchOptions: .userAlbums(),
            assetFetchOptions: .assets(forAlbumType: .album, videoType: .any)
        )

        return AlbumsDataSource(
            smartAlbumConfig: smartAlbumConfig,
            userAlbumConfig: userAlbumConfig
        )
    }

    static func fetchInitialAlbum(withVideoType type: VideoType) -> FetchedAlbum? {
        guard let smartAlbumType = smartAlbumTypes.first else { return nil }

        let assetFetchOptions = PHFetchOptions.assets(forAlbumType: .smartAlbum, videoType: type)

        return FetchedAlbum.fetchSmartAlbums(
            with: [smartAlbumType],
            assetFetchOptions: assetFetchOptions
        ).first
    }
}

extension PHFetchOptions {

    static func assets(forAlbumType albumType: PHAssetCollectionType, videoType: VideoType) -> PHFetchOptions {
        let options = PHFetchOptions.assets(forAlbumType: albumType)
        options.predicate = videoType.fetchPredicate
        return options
    }
}
