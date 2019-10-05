enum ImageFormat: String, Hashable, Codable {
    case heif
    case jpg
}

extension ImageFormat {

    var uti: String {
        switch self {
        case .heif: return "public.heic" // Note: heic, not heif!
        case .jpg: return "public.jpeg"
        }
    }

    var fileExtension: String {
        rawValue
    }

    var displayString: String {
        rawValue.uppercased()
    }
}
