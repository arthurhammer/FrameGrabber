import PhotoAlbums
import Photos

// App-specific albums configuration.
extension AlbumsDataSource {

    static let smartAlbumTypes: [PHAssetCollectionSubtype] = [
        .smartAlbumUserLibrary,
        .smartAlbumFavorites,
        .smartAlbumSlomoVideos,
        .smartAlbumTimelapses
    ]

    static func makeDefaultDataSource() -> AlbumsDataSource {
        let assetOptions = PHFetchOptions.assets(filteredBy: .videoAndLivePhoto)
            
        return AlbumsDataSource(
            smartAlbumsOptions: .init(types: smartAlbumTypes, assetOptions: assetOptions),
            userAlbumsOptions: .init(assetOptions: assetOptions)
        )
    }

    /// The "Recents" smart album to display initially.
    static func fetchFirstAlbum() -> PHAssetCollection? {
        guard let type = smartAlbumTypes.first else { return nil }
        
        return PHAssetCollection.fetchAssetCollections(
            with: .smartAlbum,
            subtype: type,
            options: nil
        ).firstObject
    }
}

extension PHFetchOptions {
    
    static func assets(filteredBy filter: PhotoLibraryFilter) -> PHFetchOptions {
        let options = PHFetchOptions()
        options.predicate = filter.photoLibraryFetchPredicate
        return options
    }
}
