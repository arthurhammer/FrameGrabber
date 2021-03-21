import Foundation
import PhotoAlbums

/// The data source for photo albums used by `AlbumPickerViewController`.
protocol AlbumPickerDataSource {
    
    /// The data source providing smart albums.
    var smartAlbumsProvider: AlbumProvider { get }
    
    /// The data source providing user albums.
    var userAlbumsProvider: AlbumProvider { get }
}

// MARK: - Implementation

/// A default data source for smart and user albums in the user's photo library.
///
/// Uses `PhotoAlbums.SmartAlbumsDataSource` and `PhotoAlbums.UserAlbumsDataSource` as a backend to
/// asynchronously fetch, filter and update albums in response to photo library changes.
class AlbumsDataSource: AlbumPickerDataSource {
    
    let smartAlbumsProvider: AlbumProvider
    let userAlbumsProvider: AlbumProvider
     
    /// - Parameters:
    ///   - smartAlbumsOptions: The types of smart albums and assets to fetch.
    ///   - userAlbumsOptions: The types of user albums and assets to fetch.
    ///   - updateQueue: The serial queue on which to perform fetches and updates.
    init(
        smartAlbumsOptions: SmartAlbumsFetchOptions = .init(),
        userAlbumsOptions: UserAlbumsFetchOptions = .init(),
        updateQueue: DispatchQueue = .init(label: "de.arthurhammer.AlbumsDataSource", qos: .userInitiated)
    ) {
        self.smartAlbumsProvider = SmartAlbumsDataSource(
            options: smartAlbumsOptions,
            updateQueue: updateQueue
        )
        
        self.userAlbumsProvider = UserAlbumsDataSource(
            options: userAlbumsOptions,
            updateQueue: updateQueue
        )
    }
}
