import Combine

/// A type that asynchronously loads and publishes photo albums.
public protocol AlbumProvider {
    
    /// The current photo albums.
    var albums: [PhotoAlbum] { get }
    
    /// A publisher that emits values whenever `albums` will change.
    var albumsPublisher: Published<[PhotoAlbum]>.Publisher { get }
    
    /// Whether albums are being loaded initially.
    var isLoading: Bool { get }
}
