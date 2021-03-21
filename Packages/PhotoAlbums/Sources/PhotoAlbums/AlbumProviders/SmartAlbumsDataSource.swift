import Combine
import Photos

public class SmartAlbumsDataSource: NSObject, AlbumProvider, PHPhotoLibraryChangeObserver {
    
    @Published public private(set) var albums = [Album]()
    @Published public private(set) var isLoading = true
    
    public var albumsPublisher: Published<[Album]>.Publisher { $albums }

    private let options: SmartAlbumsFetchOptions
    private let updateQueue: DispatchQueue
    private let photoLibrary: PHPhotoLibrary = .shared()

    public init(
        options: SmartAlbumsFetchOptions = .init(),
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

    /// Smart albums don't report any photo library changes to their asset collections. Instead, we
    /// store the album contents fetch result itself and check it for changes.
    private var fetchedAlbums = [FetchedAlbum]() {
        didSet {
            var result = fetchedAlbums.map(Album.init)
            result = options.includesEmptyAlbums ? result : result.filter { !$0.isEmpty }
            self.albums = result
        }
    }
    
    private func fetchAlbums(with options: SmartAlbumsFetchOptions) {
        updateQueue.async { [weak self] in
            let albums = FetchedAlbum.fetchSmartAlbums(
                with: options.types,
                options: options.assetOptions
            )

            // Block until values are updated. Next task then starts with the fresh data.
            DispatchQueue.main.sync {
                self?.isLoading = false
                self?.fetchedAlbums = albums
            }
        }
    }

    private func updateAlbums(with change: PHChange) {
        updateQueue.async { [weak self] in
            guard let self = self else { return }

            // Get the most recent version.
            let albums = DispatchQueue.main.sync {
                self.fetchedAlbums
            }

            let updatedAlbums = albums.compactMap {
                $0.applying(change: change)
            }

            DispatchQueue.main.sync {
                guard self.fetchedAlbums != updatedAlbums else { return }
                self.fetchedAlbums = updatedAlbums
            }
        }
    }
}
