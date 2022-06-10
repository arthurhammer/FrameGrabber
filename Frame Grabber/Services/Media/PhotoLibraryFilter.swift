enum PhotoLibraryFilter: Int {
    case videoAndLivePhoto
    case video
    case livePhoto
}

extension PhotoLibraryFilter: CaseIterable, Hashable, Codable {}

extension PhotoLibraryFilter {
    
    var title: String {
        switch self {
        case .videoAndLivePhoto:
            return Localized.videoFilterAllItems
        case .video:
            return Localized.videoFilterVideos
        case .livePhoto:
            return Localized.videoFilterLivePhotos
        }
    }
}
