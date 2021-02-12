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
        AlbumsDataSource(
            smartAlbumsOptions: .init(
                types: AlbumsDataSource.smartAlbumTypes,
                assetOptions: .assets(filteredBy: .videoAndLivePhoto)
            ),
            userAlbumsOptions: .init(
                albumOptions: .userAlbums(),
                assetOptions: .assets(filteredBy: .videoAndLivePhoto)
            )
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

    /// Default fetch options for user albums, i.e. sorted by title.
    public static func userAlbums() -> PHFetchOptions {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "localizedTitle", ascending: true)]
        return options
    }
    
    static func assets(filteredBy filter: PhotoLibraryFilter) -> PHFetchOptions {
        let options = PHFetchOptions()
        options.predicate = filter.photoLibraryFetchPredicate
        return options
    }
}
