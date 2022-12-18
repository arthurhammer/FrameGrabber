import Combine
import Photos

/// An album provider for user albums in the user's photo library.
///
/// See `SmartAlbumsDataSource` for a detailed discussion.
///
/// The initial fetch requires indexing all user albums which can be costly depending on the size
/// of the photo library. Subsequent updates are applied incrementally and are very performant.
public final class UserAlbumsDataSource: NSObject, AlbumProvider {
    
    @Published public private(set) var albums = [Album]()
    @Published public private(set) var isLoading = true
    
    public var albumsPublisher: Published<[Album]>.Publisher { $albums }
    
    private let options: UserAlbumsFetchOptions
    private let accessQueue: DispatchQueue = .main
    private let updateQueue: DispatchQueue
    private let photoLibrary: PHPhotoLibrary = .shared()

    public init(
        options: UserAlbumsFetchOptions = .init(),
        updateQueue: DispatchQueue = .init(label: "de.arthurhammer.UserAlbumsDataSource", qos: .userInitiated)
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

    // MARK: - Fetching & Updating
    
    /// The underlying user albums representation.
    private var fetchResult: MappedFetchResult<PHAssetCollection, Album>!  {
        didSet {
            var result = fetchResult.mapped
            result = options.includesEmptyAlbums ? result : (result.filter { !$0.isEmpty })
            albums = result
        }
    }

    /// Performs the initial full album fetch.
    private func fetchAlbums(with options: UserAlbumsFetchOptions) {
        updateQueue.async { [weak self] in
            let fetchResult = PHAssetCollection.fetchAssetCollections(
                with: .album,
                subtype: .albumRegular,
                options: options.albumOptions
            )

            let albums = MappedFetchResult(fetchResult: fetchResult, mapping: {
                Album(album: FetchedAlbum.fetchAssets(in: $0, options: options.assetOptions))
            })

            self?.accessQueue.sync {
                self?.isLoading = false
                self?.fetchResult = albums
            }
        }
    }

    /// Incrementally updates the albums from photo library changes.
    private func updateAlbums(with change: PHChange) {
        updateQueue.async { [weak self] in
            guard let self else { return }

            let albums = self.accessQueue.sync { self.fetchResult }

            guard let updatedAlbums = albums?.applying(change: change) else { return }

            self.accessQueue.sync {
                self.fetchResult = updatedAlbums
            }
        }
    }
}

// MARK: - PHPhotoLibraryChangeObserver

extension UserAlbumsDataSource: PHPhotoLibraryChangeObserver {

    public func photoLibraryDidChange(_ change: PHChange) {
        updateAlbums(with: change)
    }
}
