import Combine
import Photos

public class UserAlbumsDataSource: NSObject, AlbumProvider, PHPhotoLibraryChangeObserver {
    
    @Published public private(set) var albums = [Album]()
    @Published public private(set) var isLoading = true
    
    public var albumsPublisher: Published<[Album]>.Publisher { $albums }
    
    private let options: UserAlbumsFetchOptions
    private let updateQueue: DispatchQueue
    private let photoLibrary: PHPhotoLibrary = .shared()

    public init(
        options: UserAlbumsFetchOptions = .init(),
        updateQueue: DispatchQueue = .init(label: "", qos: .userInitiated)
    ) {
        self.options = options
        self.updateQueue = updateQueue
        super.init()
        photoLibrary.register(self)
        fetchAlbums(with: options)
    }

    deinit {
        photoLibrary.unregisterChangeObserver(self)
    }

    public func photoLibraryDidChange(_ change: PHChange) {
        updateAlbums(with: change)
    }
    /// Stores a mapping of asset collections to photo albums. The intial fetch is rather slow since
    /// for every asset collection we fetch its contents. After the initial fetch, photo library
    /// changes are applied incrementally and are fast.
    private var fetchResult: MappedFetchResult<PHAssetCollection, Album>!  {
        didSet {
            var result = fetchResult.array
            result = options.includesEmptyAlbums ? result : result.filter { !$0.isEmpty }
            albums = result
        }
    }

    private func fetchAlbums(with options: UserAlbumsFetchOptions) {
        updateQueue.async { [weak self] in
            
            let fetchResult = PHAssetCollection.fetchAssetCollections(
                with: .album,
                subtype: .albumRegular,
                options: options.albumOptions
            )

            let albums = MappedFetchResult<PHAssetCollection, Album>(fetchResult: fetchResult) {
                let fetched = FetchedAlbum.fetchAssets(
                    in: $0,
                    options: options.assetOptions
                )
                return Album(album: fetched)
            }

            DispatchQueue.main.sync {
                self?.isLoading = false
                self?.fetchResult = albums
            }
        }
    }

    private func updateAlbums(with change: PHChange) {
        updateQueue.async { [weak self] in
            guard let self = self else { return }

            let userAlbums = DispatchQueue.main.sync {
                self.fetchResult!
            }

            guard let changes = change.changeDetails(for: userAlbums.fetchResult) else { return }

            let updatedAlbums = userAlbums.applyChanges(changes)

            DispatchQueue.main.sync {
                self.fetchResult = updatedAlbums
            }
        }
    }
}
