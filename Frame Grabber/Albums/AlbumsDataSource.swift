import Photos

/// Data source for Photo Library smart and user albums.
/// Fetches, filters and updates the albums in response to Photo Library changes.
class AlbumsDataSource: NSObject, PHPhotoLibraryChangeObserver {

    static let defaultSmartAlbumTypes: [PHAssetCollectionSubtype] =
        [.smartAlbumVideos, .smartAlbumFavorites, .smartAlbumTimelapses, .smartAlbumSlomoVideos]

    // Handlers are called on the main thread.
    var smartAlbumsChangedHandler: (([Album]) -> ())?
    var userAlbumsChangedHandler: (([Album]) -> ())?

    // Smart albums don't get any Photo Library update information. Instead, store the
    // fetch results to check for updates instead.
    private(set) var smartAlbums = [FetchedAlbum]() {
        didSet {
            guard smartAlbums != oldValue else { return }
            smartAlbumsChangedHandler?(smartAlbums)
        }
    }

    // User albums do get change notifications, don't keep the fetch results.
    private(set) var userAlbums = [StaticAlbum]() {
        didSet {
            guard userAlbums != oldValue else { return }
            userAlbumsChangedHandler?(userAlbums)
        }
    }

    private var userAlbumsBaseFetchResult: PHFetchResult<PHAssetCollection>
    private let updateQueue: DispatchQueue
    private let photoLibrary: PHPhotoLibrary

    init(smartAlbumTypes: [PHAssetCollectionSubtype] = AlbumsDataSource.defaultSmartAlbumTypes,
         userAlbumsBaseFetchResult: PHFetchResult<PHAssetCollection> = PHAssetCollection.fetchUserAlbums(with: .userAlbums()),
         updateQueue: DispatchQueue = .init(label: "me.ahammer.\(String(describing: AlbumsDataSource.self))", qos: .userInitiated),
         photoLibrary: PHPhotoLibrary = .shared()) {

        self.userAlbumsBaseFetchResult = userAlbumsBaseFetchResult
        self.updateQueue = updateQueue
        self.photoLibrary = photoLibrary

        super.init()

        photoLibrary.register(self)

        initSmartAlbums(with: smartAlbumTypes)
        initUserAlbums(with: userAlbumsBaseFetchResult)
    }

    deinit {
        photoLibrary.unregisterChangeObserver(self)
    }

    // MARK: PHPhotoLibraryChangeObserver

    func photoLibraryDidChange(_ change: PHChange) {
        updateSmartAlbums(with: change)
        updateUserAlbums(with: change)
    }

    // Photos API is rather limited. Filtering albums to not be empty for videos and
    // getting asset count and key asset for every album requires fetching all albums
    // *and* their contents on every Photo Library update. This can be very slow.

    // During updates, instance var access is synchronized on main. Current task blocks
    // until changes are committed so changes are performed in strict sequential order.
    // Otherwise, subsequent tasks might start with stale data (`smartAlbums`/ `userAlbumsBaseFetchResult`).

    // MARK: Updating Smart Albums

    private func initSmartAlbums(with types: [PHAssetCollectionSubtype]) {
        updateQueue.async { [weak self] in
            let smartAlbums = FetchedAlbum.fetchSmartAlbums(with: types, assetFetchOptions: .smartAlbumVideos())

            DispatchQueue.main.sync {
                self?.smartAlbums = smartAlbums
            }
        }
    }

    private func updateSmartAlbums(with change: PHChange) {
        updateQueue.async { [weak self] in
            guard let this = self else { return }

            let smartAlbums = DispatchQueue.main.sync {
                this.smartAlbums
            }

            let updatedAlbums: [FetchedAlbum] = smartAlbums.compactMap {
                let changes = change.changeDetails(for: $0)
                return (changes == nil) ? $0 : changes!.albumAfterChanges
            }

            DispatchQueue.main.sync {
                self?.smartAlbums = updatedAlbums
            }
        }
    }

    // MARK: Updating User Albums

    // (Filtering 100 albums takes in the order of 1 second on an iPhone 6. Large photo
    // libraries could have hundreds to thousands of albums.)

    private func initUserAlbums(with fetchResult: PHFetchResult<PHAssetCollection>) {
        updateQueue.async { [weak self] in
            let userAlbums = fetchResult
                .filteringEmptyAlbums(for: .userAlbumVideos())
                .map(StaticAlbum.init)

            DispatchQueue.main.sync {
                self?.userAlbumsBaseFetchResult = fetchResult
                self?.userAlbums = userAlbums
            }
        }
    }

    private func updateUserAlbums(with change: PHChange) {
        updateQueue.async { [weak self] in
            guard let this = self else { return }

            let fetchResult = DispatchQueue.main.sync {
                this.userAlbumsBaseFetchResult
            }

            guard let updatedFetchResult = change.changeDetails(for: fetchResult)?.fetchResultAfterChanges else { return }

            let updatedAlbums = updatedFetchResult
                .filteringEmptyAlbums(for: .userAlbumVideos())
                .map(StaticAlbum.init)

            DispatchQueue.main.sync {
                self?.userAlbumsBaseFetchResult = updatedFetchResult
                self?.userAlbums = updatedAlbums
            }
        }
    }
}

// MARK: - Util

private extension PHFetchResult where ObjectType == PHAssetCollection {
    /// Returns albums containing at least one asset for the given fetch options.
    /// - Note: This synchronously fetches all collections **and** their assets.
    func filteringEmptyAlbums(for options: PHFetchOptions) -> [FetchedAlbum] {
        var filteredAlbums = [FetchedAlbum]()

        enumerateObjects { album, _, _ in
            let album = FetchedAlbum.fetchAssets(in: album, options: options)

            if album.count > 0 {
                filteredAlbums.append(album)
            }
        }

        return filteredAlbums
    }
}
