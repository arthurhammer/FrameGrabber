import Photos

extension PHChange {

    /// Returns detailed changes for the album's asset collection and fetch result. Returns nil if
    /// nothing changed.
    func changeDetails(for album: FetchedAlbum) -> FetchedAlbum.ChangeDetails? {
        let albumChanges = changeDetails(for: album.assetCollection)
        let assetChanges = changeDetails(for: album.fetchResult)
        let didChange = (albumChanges, assetChanges) != (nil, nil)
        let wasDeleted = albumChanges?.objectWasDeleted ?? false

        guard didChange else { return nil }

        let updatedAlbum: FetchedAlbum?

        if wasDeleted {
            updatedAlbum = nil
        } else {
            updatedAlbum = FetchedAlbum(
                assetCollection: albumChanges?.objectAfterChanges ?? album.assetCollection,
                fetchResult: assetChanges?.fetchResultAfterChanges ?? album.fetchResult
            )
        }

        return FetchedAlbum.ChangeDetails(
            albumAfterChanges: updatedAlbum,
            assetCollectionChanges: albumChanges,
            fetchResultChanges: assetChanges
        )
    }
}
