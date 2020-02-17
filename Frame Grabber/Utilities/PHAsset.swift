import Photos

extension PHAsset {
    
    var dimensions: CGSize {
        CGSize(width: pixelWidth, height: pixelHeight)
    }

    var isLivePhoto: Bool {
        mediaSubtypes.contains(.photoLive)
    }
}
