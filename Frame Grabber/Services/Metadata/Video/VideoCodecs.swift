import CoreMedia
import UniformTypeIdentifiers

extension CMFormatDescription.MediaSubType {
    
    /// A description of the codec for display.
    ///
    /// The strings are not localized as they are considered international.
    var displayString: String {
        switch self {
        case .h263: return "H.263"
        case .h264: return "H.264"
        case .hevc, .hevcWithAlpha: return "HEVC"
        default: return fourCharacterDisplayString
        }
    }
    
    var fourCharacterDisplayString: String {
        String(describing: self).replacingOccurrences(of: "'", with: "").uppercased()
    }
}

extension UTType {
    
    /// A description of the container format for display.
    ///
    /// The strings are not localized as they are considered international.
    var displayString: String {
        switch self {
        case .quickTimeMovie: return "QuickTime Movie"
        case .mpeg, .mpeg2Video: return "MPEG Movie"
        case .mpeg4Movie: return "MPEG-4 Movie"
        default: return identifier
        }
    }
}
