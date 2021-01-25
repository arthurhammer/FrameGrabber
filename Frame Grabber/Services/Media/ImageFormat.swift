import AVFoundation

enum ImageFormat: String {
    case heif
    case jpeg
}

extension ImageFormat: CaseIterable, Hashable, Codable {}

extension ImageFormat {

    var uti: String {
        switch self {
        case .heif: return "public.heic"  // Note: Must be heic, not heif
        case .jpeg: return "public.jpeg"
        }
    }
    
    /// Whether encoding images in this format is supported in the current environment (when using
    /// system-level encoding like `CGImageDestinationCreate`).
    var isEncodingSupported: Bool {
        let supportedTypes = CGImageDestinationCopyTypeIdentifiers() as NSArray
        return supportedTypes.contains(uti)
    }
    
    /// If the encoding is supported in the current environment returns itself, otherwise `.jpeg`.
    var fallbackFormat: ImageFormat {
        assert(ImageFormat.jpeg.isEncodingSupported)
        return isEncodingSupported ? self : .jpeg
    }

    var fileExtension: String {
        rawValue
    }

    var displayString: String {
        rawValue.uppercased()
    }
}
