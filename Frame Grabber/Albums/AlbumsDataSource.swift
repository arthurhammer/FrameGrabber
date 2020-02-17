import Photos

/// Data source for Photo Library smart and user albums.
/// Fetches, filters and updates the albums in response to Photo Library changes.
class AlbumsDataSource: NSObject, PHPhotoLibraryChangeObserver {

    static let defaultSmartAlbumTypes: [PHAssetCollectionSubtype] =
        [.smartAlbumUserLibrary, .smartAlbumFavorites, .smartAlbumTimelapses, .smartAlbumSlomoVideos]

    // Handlers are called on the main thread.
    var smartAlbumsChangedHandler: (([Album]) -> ())?
    var userAlbumsChangedHandler: (([Album]) -> ())?

    // Smart albums don't get any Photo Library update information. Instead, store the
    // fetch results to check for updates instead.
    private(set) var smartAlbums = [FetchedAlbum]() {
        didSet { smartAlbumsChangedHandler?(smartAlbums) }
    }

    // For user albums, static album suffices.
    private(set) var userAlbums = [StaticAlbum]() {
        didSet { userAlbumsChangedHandler?(userAlbums) }
    }

    private(set) var didInitializeSmartAlbums = false
    private(set) var didInitializeUserAlbums = false

    private var userAlbumsFetchResult: MappedFetchResult<PHAssetCollection, StaticAlbum>!  {
        didSet { userAlbums = userAlbumsFetchResult.array.filter { !$0.isEmpty } }
    }

    private let updateQueue: DispatchQueue
    private let photoLibrary: PHPhotoLibrary

    init(smartAlbumTypes: [PHAssetCollectionSubtype] = AlbumsDataSource.defaultSmartAlbumTypes,
         smartAlbumAssetFetchOptions: PHFetchOptions = .assets(forAlbumType: .smartAlbum, videoType: .any),
         userAlbumFetchOptions: PHFetchOptions = .userAlbums(),
         userAlbumAssetFetchOptions: PHFetchOptions = .assets(forAlbumType: .album, videoType: .any),
         updateQueue: DispatchQueue = .init(label: String(describing: AlbumsDataSource.self), qos: .userInitiated),
         photoLibrary: PHPhotoLibrary = .shared()) {

        self.updateQueue = updateQueue
        self.photoLibrary = photoLibrary

        super.init()

        photoLibrary.register(self)

        initSmartAlbums(with: smartAlbumTypes, assetFetchOptions: smartAlbumAssetFetchOptions)
        initUserAlbums(with: userAlbumFetchOptions, assetFetchOptions: userAlbumAssetFetchOptions)
    }

    deinit {
        photoLibrary.unregisterChangeObserver(self)
    }

    // MARK: PHPhotoLibraryChangeObserver

    func photoLibraryDidChange(_ change: PHChange) {
        updateSmartAlbums(with: change)
        updateUserAlbums(with: change)
    }
}

private extension AlbumsDataSource {

    // MARK: Updating Smart Albums

    func initSmartAlbums(with types: [PHAssetCollectionSubtype], assetFetchOptions: PHFetchOptions) {
        updateQueue.async { [weak self] in
            let smartAlbums = FetchedAlbum.fetchSmartAlbums(with: types, assetFetchOptions: assetFetchOptions)

            // Instance vars synchronized on main. `sync` to block current task until done
            // so subsequent tasks start with correct data.
            DispatchQueue.main.sync {
                self?.didInitializeSmartAlbums = true
                self?.smartAlbums = smartAlbums
            }
        }
    }

    func updateSmartAlbums(with change: PHChange) {
        updateQueue.async { [weak self] in
            guard let self = self else { return }

            let smartAlbums = DispatchQueue.main.sync {
                self.smartAlbums
            }

            let updatedAlbums: [FetchedAlbum] = smartAlbums.compactMap {
                let changes = change.changeDetails(for: $0)
                return (changes == nil) ? $0 : changes!.albumAfterChanges
            }

            DispatchQueue.main.sync {
                guard self.smartAlbums != updatedAlbums else { return }
                self.smartAlbums = updatedAlbums
            }
        }
    }

    // MARK: Updating User Albums

    func initUserAlbums(with albumFetchOptions: PHFetchOptions, assetFetchOptions: PHFetchOptions) {
        updateQueue.async { [weak self] in
            let fetchResult = PHAssetCollection.fetchUserAlbums(with: albumFetchOptions)

            let userAlbums = MappedFetchResult(fetchResult: fetchResult) {
                StaticAlbum(album: FetchedAlbum.fetchAssets(in: $0, options: assetFetchOptions))
            }

            DispatchQueue.main.sync {
                self?.didInitializeUserAlbums = true
                self?.userAlbumsFetchResult = userAlbums
            }
        }
    }

    func updateUserAlbums(with change: PHChange) {
        updateQueue.async { [weak self] in
            guard let self = self else { return }

            let userAlbums = DispatchQueue.main.sync {
                self.userAlbumsFetchResult!
            }

            guard let changes = change.changeDetails(for: userAlbums.fetchResult) else { return }
            let updatedAlbums = applyIncrementalChanges(changes, to: userAlbums)

            DispatchQueue.main.sync {
                self.userAlbumsFetchResult = updatedAlbums
            }
        }
    }
}
