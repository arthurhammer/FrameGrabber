import Combine

/// A type that asynchronously loads and publishes photo albums.
public protocol AlbumProvider {
    
    /// The current photo albums.
    var albums: [Album] { get }
    
    /// A publisher that emits values whenever `albums` will change.
    var albumsPublisher: Published<[Album]>.Publisher { get }
    
    /// Whether albums are being loaded initially.
    var isLoading: Bool { get }
}
