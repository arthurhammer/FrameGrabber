import Photos

extension PHAsset {
    
    public var dimensions: CGSize {
        CGSize(width: pixelWidth, height: pixelHeight)
    }

    public var isVideo: Bool {
        mediaType == .video
    }

    public var isLivePhoto: Bool {
        mediaSubtypes.contains(.photoLive)
    }
}
