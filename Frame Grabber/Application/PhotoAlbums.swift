import PhotoAlbums
import Photos

extension AlbumsDataSource {

    static let smartAlbumTypes: [PHAssetCollectionSubtype] = [
        .smartAlbumUserLibrary,
        .smartAlbumFavorites,
        .smartAlbumTimelapses,
        .smartAlbumSlomoVideos
    ]

    static func `default`() -> AlbumsDataSource {
        let smartAlbumConfig = SmartAlbumConfiguration(types: AlbumsDataSource.smartAlbumTypes,
                                                       assetFetchOptions: .assets(forAlbumType: .smartAlbum, videoType: .any))

        let userAlbumConfig = UserAlbumConfiguration(albumFetchOptions: .userAlbums(),
                                                     assetFetchOptions: .assets(forAlbumType: .album, videoType: .any))

        return AlbumsDataSource(smartAlbumConfig: smartAlbumConfig, userAlbumConfig: userAlbumConfig)
    }
}

extension PHFetchOptions {

    static func assets(forAlbumType albumType: PHAssetCollectionType, videoType: VideoType) -> PHFetchOptions {
        let options = PHFetchOptions.assets(forAlbumType: albumType)
        options.predicate = videoType.fetchPredicate
        return options
    }
}
