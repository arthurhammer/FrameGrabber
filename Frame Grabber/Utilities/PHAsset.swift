import Photos

extension PHAsset {
    var dimensions: CGSize {
        CGSize(width: pixelWidth, height: pixelHeight)
    }
}
