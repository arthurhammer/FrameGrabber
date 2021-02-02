import CoreMedia

extension CMFormatDescription.MediaSubType {
    
    /// A description of the format for display. The strings are not localized.
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
