import AVFoundation

extension AVAsset {
    var videoTrack: AVAssetTrack? {
        tracks(withMediaType: .video).first
    }

    var dimensions: CGSize? {
        videoTrack?.naturalSize
    }

    var frameRate: Float? {
        videoTrack?.nominalFrameRate
    }
}
