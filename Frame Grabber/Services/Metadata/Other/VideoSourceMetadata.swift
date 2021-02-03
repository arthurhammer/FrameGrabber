/// The set of metadata for a `VideoSource` and its associated video.
struct VideoSourceMetadata: Equatable {
    
    /// Metadata for the video asset that was loaded from the source.
    var video: VideoMetadata?
    
    /// File metadata if the video is represented by a local file (typically `nil` if it is an
    /// `AVComposition`).
    var file: FileMetadata?
    
    /// Photo library metadata if the video source is the photo library.
    var photoLibrary: PhotoLibraryMetadata?
}
