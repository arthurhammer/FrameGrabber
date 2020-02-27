import AVFoundation

extension AVAsset {
    var videoTrack: AVAssetTrack? {
        tracks(withMediaType: .video).first
    }

    var dimensions: CGSize? {
        guard let videoTrack = videoTrack else { return .zero }
        return videoTrack.naturalSize.applying(videoTrack.preferredTransform)
    }

    var frameRate: Float? {
        videoTrack?.nominalFrameRate
    }
}
