import AVFoundation

extension AVAsset {
    
    var videoTrack: AVAssetTrack? {
        tracks(withMediaType: .video).first
    }

    var dimensions: CGSize? {
        guard let videoTrack = videoTrack else { return .zero }
        let rotated = videoTrack.naturalSize.applying(videoTrack.preferredTransform)
        return CGSize(width: abs(rotated.width), height: abs(rotated.height))
    }

    var frameRate: Float? {
        videoTrack?.nominalFrameRate
    }
}
