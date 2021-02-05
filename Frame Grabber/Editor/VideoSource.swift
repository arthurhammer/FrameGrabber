import Photos

enum VideoSource {
    case photoLibrary(PHAsset)
    case url(URL)
}

extension VideoSource {
    
    /// The asset if the receiver is `.photoLibrary`.
    var asset: PHAsset? {
        switch self {
        case .photoLibrary(let asset): return asset
        case .url: return nil
        }
    }

    /// The url if the receiver is `.url`.
    var url: URL? {
        switch self {
        case .photoLibrary: return nil
        case .url(let url): return url
        }
    }
}
