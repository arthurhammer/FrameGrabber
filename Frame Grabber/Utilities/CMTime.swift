import AVKit

extension CMTime {
    init(seconds: Double, preferredTimeScale: CMTimeScale = CMTimeScale(NSEC_PER_SEC)) {
        self.init(seconds: seconds, preferredTimescale: preferredTimeScale)
    }
}
