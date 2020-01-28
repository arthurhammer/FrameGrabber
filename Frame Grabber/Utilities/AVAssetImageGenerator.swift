import AVFoundation

extension AVAssetImageGenerator {
    /// A generator with full frame size, no tolerance and preferred track transform.
    static func `default`(for video: AVAsset) -> AVAssetImageGenerator {
        let generator = AVAssetImageGenerator(asset: video)
        generator.maximumSize = .zero
        generator.requestedTimeToleranceBefore = .zero
        generator.requestedTimeToleranceAfter = .zero
        generator.appliesPreferredTrackTransform = true
        return generator
    }
}
