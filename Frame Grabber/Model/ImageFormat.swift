enum ImageFormat: String {
    case heif
    case jpeg
}

extension ImageFormat: CaseIterable, Hashable, Codable {}

extension ImageFormat {

    var uti: String {
        switch self {
        case .heif: return "public.heic"  // Note: heic, not heif!
        case .jpeg: return "public.jpeg"
        }
    }

    var fileExtension: String {
        rawValue
    }

    var displayString: String {
        rawValue.uppercased()
    }
}
