import Combine
import Photos

/// Data source for smart albums and user albums in the user's photo library.
///
/// Asynchronously fetches, filters and updates albums in response to photo library changes. See
/// `SmartAlbumsOptions` for details.
public class AlbumsDataSource {

    @Published public private(set) var smartAlbums = [Album]()
    @Published public private(set) var isLoadingSmartAlbums = true
    
    @Published public private(set) var userAlbums = [Album]()
    @Published public private(set) var isLoadingUserAlbums = true
    
    private let smartAlbumsDataSource: SmartAlbumsDataSource
    private let userAlbumsDataSource: UserAlbumsDataSource
    private var bindings = Set<AnyCancellable>()

    public init(
        smartAlbumsOptions: SmartAlbumsOptions = .init(),
        userAlbumsOptions: UserAlbumsOptions = .init(),
        updateQueue: DispatchQueue = .init(label: "", qos: .userInitiated)
    ) {
        self.smartAlbumsDataSource = SmartAlbumsDataSource(
            options: smartAlbumsOptions,
            updateQueue: updateQueue
        )
        self.userAlbumsDataSource = UserAlbumsDataSource(
            options: userAlbumsOptions,
            updateQueue: updateQueue
        )
                
        smartAlbumsDataSource.$albums
            .sink { [weak self] in self?.smartAlbums = $0 }
            .store(in: &bindings)
        
        smartAlbumsDataSource.$isLoading
            .sink { [weak self] in self?.isLoadingSmartAlbums = $0 }
            .store(in: &bindings)
        
        userAlbumsDataSource.$albums
            .sink { [weak self] in self?.userAlbums = $0 }
            .store(in: &bindings)
        
        userAlbumsDataSource.$isLoading
            .sink { [weak self] in self?.isLoadingUserAlbums = $0 }
            .store(in: &bindings)
    }
}
