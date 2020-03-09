import Photos

extension AlbumsDataSource {
    static let defaultSmartAlbumTypes: [PHAssetCollectionSubtype] = [
        .smartAlbumUserLibrary,
        .smartAlbumFavorites,
        .smartAlbumTimelapses,
        .smartAlbumSlomoVideos
    ]
}

/// Data source for smart albums and user albums in the user's photo library.
///
/// Asynchronously fetches, filters and updates the albums in response to photo library
/// changes.
class AlbumsDataSource: NSObject, PHPhotoLibraryChangeObserver {

    // MARK: Smart Albums

    private(set) var smartAlbums = [AnyAlbum]() {
        didSet { smartAlbumsChangedHandler?(smartAlbums) }
    }

    /// The handler is called on the main thread.
    var smartAlbumsChangedHandler: (([AnyAlbum]) -> ())?
    private(set) var didInitializeSmartAlbums = false

    // MARK: User Albums

    /// The handler is called on the main thread.
    var userAlbumsChangedHandler: (([AnyAlbum]) -> ())?
    private(set) var didInitializeUserAlbums = false

    private(set) var userAlbums = [AnyAlbum]() {
        didSet { userAlbumsChangedHandler?(userAlbums) }
    }

    // MARK: Lifecycle

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

    func photoLibraryDidChange(_ change: PHChange) {
        updateSmartAlbums(with: change)
        updateUserAlbums(with: change)
    }

    // MARK: - Private

    private let updateQueue: DispatchQueue
    private let photoLibrary: PHPhotoLibrary

    // MARK: Updating Smart Albums

    /// `PHAssetCollection` instances of type smart album don't report any photo library
    /// changes. As a workaround, store the album's contents as a fetch result that we can
    /// check against changes.
    private var fetchedSmartAlbums = [FetchedAlbum]() {
        didSet { smartAlbums = fetchedSmartAlbums.map(AnyAlbum.init) }
    }

    private func initSmartAlbums(with types: [PHAssetCollectionSubtype], assetFetchOptions: PHFetchOptions) {
        updateQueue.async { [weak self] in
            let smartAlbums = FetchedAlbum.fetchSmartAlbums(with: types, assetFetchOptions: assetFetchOptions)

            // Instance vars synchronized on main. `sync` to block current task until done
            // so subsequent tasks start with correct data.
            DispatchQueue.main.sync {
                self?.didInitializeSmartAlbums = true
                self?.fetchedSmartAlbums = smartAlbums
            }
        }
    }

    private func updateSmartAlbums(with change: PHChange) {
        updateQueue.async { [weak self] in
            guard let self = self else { return }

            let smartAlbums = DispatchQueue.main.sync {
                self.fetchedSmartAlbums
            }

            let updatedAlbums: [FetchedAlbum] = smartAlbums.compactMap {
                let changes = change.changeDetails(for: $0)
                return (changes == nil) ? $0 : changes!.albumAfterChanges
            }

            DispatchQueue.main.sync {
                guard self.fetchedSmartAlbums != updatedAlbums else { return }
                self.fetchedSmartAlbums = updatedAlbums
            }
        }
    }

    // MARK: Updating User Albums

    private var userAlbumsFetchResult: MappedFetchResult<PHAssetCollection, AnyAlbum>!  {
        didSet { userAlbums = userAlbumsFetchResult.array.filter { !$0.isEmpty } }
    }

    private func initUserAlbums(with albumFetchOptions: PHFetchOptions, assetFetchOptions: PHFetchOptions) {
        updateQueue.async { [weak self] in
            let fetchResult = PHAssetCollection.fetchUserAlbums(with: albumFetchOptions)

            let userAlbums = MappedFetchResult(fetchResult: fetchResult) {
                AnyAlbum(album: FetchedAlbum.fetchAssets(in: $0, options: assetFetchOptions))
            }

            DispatchQueue.main.sync {
                self?.didInitializeUserAlbums = true
                self?.userAlbumsFetchResult = userAlbums
            }
        }
    }

    private func updateUserAlbums(with change: PHChange) {
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
