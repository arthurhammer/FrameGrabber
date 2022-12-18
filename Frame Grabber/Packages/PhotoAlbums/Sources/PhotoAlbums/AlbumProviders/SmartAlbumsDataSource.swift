import Combine
import Photos

/// An album provider for smart albums in the user's photo library.
///
/// This class solves several `PhotoKit` limitations.
///
/// First, it supports fetching only specific albums matching certain criteria (e.g., only albums
/// that contain videos or Live Photos). Second, it provides an exact count of the number of items
/// in the album taking the specified filter into account. Third, it preloads a key asset that can
/// be used to generate album thumbnails directly. Finally, it performs all of this work fully
/// asynchronously in the background and keeps the data up to date whenever the photo library
/// changes.
public final class SmartAlbumsDataSource: NSObject, AlbumProvider {
    
    @Published public private(set) var albums = [Album]()
    @Published public private(set) var isLoading = true
    
    public var albumsPublisher: Published<[Album]>.Publisher { $albums }

    private let options: SmartAlbumsFetchOptions
    private let accessQueue: DispatchQueue = .main
    private let updateQueue: DispatchQueue
    private let photoLibrary: PHPhotoLibrary = .shared()

    /// - Parameters:
    ///   - options: Options to specify which album types and which types of assets to fetch.
    ///   - updateQueue: The serial queue on which to perform fetches and updates.
    public init(
        options: SmartAlbumsFetchOptions = .init(),
        updateQueue: DispatchQueue = .init(label: "de.arthurhammer.SmartAlbumsDataSource", qos: .userInitiated)
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

    /// The underlying smart albums representation.
    ///
    /// Unlike for user albums, `PhotoKit` does not report changes for a smart album `PHAssetCollection`.
    /// Instead, we cache the album contents themselves as a `FetchedAlbum` which we use to check
    /// against changes.
    private var fetchedAlbums = [FetchedAlbum]() {
        didSet {
            var result = fetchedAlbums.map(Album.init)
            result = options.includesEmptyAlbums ? result : (result.filter { !$0.isEmpty })
            
            if result != albums {
                albums = result
            }
        }
    }
    
    /// Performs the initial full album fetch.
    private func fetchAlbums(with options: SmartAlbumsFetchOptions) {
        updateQueue.async { [weak self] in
            let albums = FetchedAlbum.fetchSmartAlbums(
                with: options.types,
                options: options.assetOptions
            )

            self?.accessQueue.sync {
                self?.isLoading = false
                self?.fetchedAlbums = albums
            }
        }
    }

    /// Incrementally updates the albums from photo library changes.
    private func updateAlbums(with change: PHChange) {
        updateQueue.async { [weak self] in
            guard let self else { return }

            let albums = self.accessQueue.sync { self.fetchedAlbums }

            let updatedAlbums = albums.compactMap {
                $0.applying(change: change)
            }

            self.accessQueue.sync {
                self.fetchedAlbums = updatedAlbums
            }
        }
    }
}

// MARK: - PHPhotoLibraryChangeObserver

extension SmartAlbumsDataSource: PHPhotoLibraryChangeObserver {

    public func photoLibraryDidChange(_ change: PHChange) {
        updateAlbums(with: change)
    }
}
