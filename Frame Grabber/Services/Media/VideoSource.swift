import Photos

enum VideoSource {
    case photoLibrary(PHAsset)
    case url(URL)
    case camera(URL)
}

extension VideoSource {
    
    /// The asset if the receiver is `.photoLibrary`.
    var photoLibraryAsset: PHAsset? {
        switch self {
        case .photoLibrary(let asset): return asset
        case .url, .camera: return nil
        }
    }

    /// The url if the receiver is `.url` or `.camera`.
    var url: URL? {
        switch self {
        case .photoLibrary: return nil
        case .url(let url), .camera(let url): return url
        }
    }
}
