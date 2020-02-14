import Photos

extension PHAsset {
    var dimensions: CGSize {
        CGSize(width: pixelWidth, height: pixelHeight)
    }
}

extension PHAsset {
    var isLivePhoto: Bool {
        mediaSubtypes.contains(.photoLive)
    }
}
