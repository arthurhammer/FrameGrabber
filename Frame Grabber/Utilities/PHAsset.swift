import Photos

extension PHAsset {
    
    var dimensions: CGSize {
        CGSize(width: pixelWidth, height: pixelHeight)
    }

    var isVideo: Bool {
        mediaType == .video
    }

    var isLivePhoto: Bool {
        mediaSubtypes.contains(.photoLive)
    }
}
