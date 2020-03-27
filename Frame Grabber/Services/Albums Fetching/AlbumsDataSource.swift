import Photos
import Combine

extension AlbumsDataSource {

    static let defaultSmartAlbumTypes: [PHAssetCollectionSubtype] = [
        .smartAlbumUserLibrary,
        .smartAlbumFavorites,
        .smartAlbumTimelapses,
        .smartAlbumSlomoVideos
    ]

    struct SmartAlbumConfiguration {
        let types: [PHAssetCollectionSubtype] = AlbumsDataSource.defaultSmartAlbumTypes
        let assetFetchOptions: PHFetchOptions = .assets(forAlbumType: .smartAlbum, videoType: .any)
    }

    struct UserAlbumConfiguration {
        let albumFetchOptions: PHFetchOptions = .userAlbums()
        let assetFetchOptions: PHFetchOptions = .assets(forAlbumType: .album, videoType: .any)
    }
}

/// Data source for smart albums and user albums in the user's photo library.
///
/// Asynchronously fetches, filters and updates the albums in response to photo library
/// changes.
class AlbumsDataSource: NSObject, PHPhotoLibraryChangeObserver {

    @Published private(set) var smartAlbums = [AnyAlbum]()
    @Published private(set) var isLoadingSmartAlbums = true

    @Published private(set) var userAlbums = [AnyAlbum]()
    @Published private(set) var isLoadingUserAlbums = true

    private let updateQueue: DispatchQueue
    private let photoLibrary: PHPhotoLibrary

    init(smartAlbumConfig: SmartAlbumConfiguration = .init(),
         userAlbumConfig: UserAlbumConfiguration = .init(),
         updateQueue: DispatchQueue = .init(label: AlbumsDataSource.name, qos: .userInitiated),
         photoLibrary: PHPhotoLibrary = .shared()) {

        self.updateQueue = updateQueue
        self.photoLibrary = photoLibrary

        super.init()

        photoLibrary.register(self)

        fetchSmartAlbums(with: smartAlbumConfig)
        fetchUserAlbums(with: userAlbumConfig)
    }

    deinit {
        photoLibrary.unregisterChangeObserver(self)
    }

    func photoLibraryDidChange(_ change: PHChange) {
        updateSmartAlbums(with: change)
        updateUserAlbums(with: change)
    }

    // MARK: Updating Smart Albums

    /// `PHAssetCollection` instances of type smart album don't report any photo library
    /// changes. As a workaround, store the album's contents as a fetch result that we can
    /// check against changes.
    private var fetchedSmartAlbums = [FetchedAlbum]() {
        didSet { smartAlbums = fetchedSmartAlbums.map(AnyAlbum.init) }
    }

    private func fetchSmartAlbums(with config: SmartAlbumConfiguration) {
        updateQueue.async { [weak self] in
            let smartAlbums = FetchedAlbum.fetchSmartAlbums(with: config.types, assetFetchOptions: config.assetFetchOptions)

            // Instance vars synchronized on main. `sync` to block current task until done
            // so subsequent tasks start with correct data.
            DispatchQueue.main.sync {
                self?.isLoadingSmartAlbums = false
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

    private func fetchUserAlbums(with config: UserAlbumConfiguration) {
        updateQueue.async { [weak self] in
            let fetchResult = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumRegular, options: config.albumFetchOptions)

            let userAlbums = MappedFetchResult(fetchResult: fetchResult) {
                AnyAlbum(album: FetchedAlbum.fetchAssets(in: $0, options: config.assetFetchOptions))
            }

            DispatchQueue.main.sync {
                self?.isLoadingUserAlbums = false
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

            let updatedAlbums = userAlbums.applyChanges(changes)

            DispatchQueue.main.sync {
                self.userAlbumsFetchResult = updatedAlbums
            }
        }
    }
}
