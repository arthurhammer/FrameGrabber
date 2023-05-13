import Foundation
import ImageIO

enum ImageFormat: String {
    case jpeg
    case png
    case heif
}

extension ImageFormat: CaseIterable, Hashable, Codable {}

extension ImageFormat {

    var uti: String {
        switch self {
        case .jpeg: return "public.jpeg"
        case .png: return "public.png"
        case .heif: return "public.heic"  // Note: Must be heic, not heif
        }
    }
    
    var fileExtension: String {
        rawValue
    }

    var displayString: String {
        rawValue.uppercased()
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
        assert(ImageFormat.png.isEncodingSupported)
        
        return isEncodingSupported ? self : .jpeg
    }
    
    /// Whether the format supports lossy compression.
    var isLossyCompressionSupported: Bool {
        switch self {
        case .jpeg, .heif: return true
        case .png: return false
        }
    }
}
