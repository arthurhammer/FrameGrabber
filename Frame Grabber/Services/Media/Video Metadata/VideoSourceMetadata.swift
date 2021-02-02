/// The set of metadata for a `VideoSource` and its associated video.
struct VideoSourceMetadata {
    
    /// Metadata for the video asset that was loaded from the source.
    let video: VideoMetadata
    
    /// File metadata if the video is represented by a local file (typically `nil` if it is an
    /// `AVComposition`).
    let file: FileMetadata?
    
    /// Photo library metadata if the video source is the photo library.
    let photoLibrary: PhotoLibraryMetadata?
}
