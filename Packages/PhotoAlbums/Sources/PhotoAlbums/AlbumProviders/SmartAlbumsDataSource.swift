import Combine
import Photos

public class SmartAlbumsDataSource: NSObject, AlbumProvider, PHPhotoLibraryChangeObserver {
    
    @Published public private(set) var albums = [Album]()
    @Published public private(set) var isLoading = true
    
    public var albumsPublisher: Published<[Album]>.Publisher { $albums }

    private let options: SmartAlbumsOptions
    private let updateQueue: DispatchQueue
    private let photoLibrary: PHPhotoLibrary = .shared()

    public init(
        options: SmartAlbumsOptions = .init(),
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
            result = options.includesEmpty ? result : result.filter { !$0.isEmpty }
            self.albums = result
        }
    }
    
    private func fetchAlbums(with options: SmartAlbumsOptions) {
        updateQueue.async { [weak self] in
            let albums = FetchedAlbum.fetchSmartAlbums(
                with: options.types,
                assetFetchOptions: options.assetOptions
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
            let smartAlbums = DispatchQueue.main.sync {
                self.fetchedAlbums
            }

            let updatedAlbums: [FetchedAlbum] = smartAlbums.compactMap {
                let changes = change.changeDetails(for: $0)
                return (changes == nil) ? $0 : changes!.albumAfterChanges
            }

            DispatchQueue.main.sync {
                guard self.fetchedAlbums != updatedAlbums else { return }
                self.fetchedAlbums = updatedAlbums
            }
        }
    }
}
