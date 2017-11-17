import AVKit

extension CMTime {
    static let zero = kCMTimeZero

    init(interval: TimeInterval, preferredTimeScale: CMTimeScale = CMTimeScale(NSEC_PER_SEC)) {
        self.init(seconds: interval, preferredTimescale: preferredTimeScale)
    }
}

extension AVAssetImageGenerator {

    func copyCGImage(atExactTime time: CMTime, handler: (Error?, CGImage?) -> ()) {
        // Save/restore state
        let oldToleranceBefore = requestedTimeToleranceBefore
        let oldToleranceAfter = requestedTimeToleranceAfter

        let restoreState = { 
            self.requestedTimeToleranceBefore = oldToleranceBefore
            self.requestedTimeToleranceAfter = oldToleranceAfter
        }

        requestedTimeToleranceBefore = .zero
        requestedTimeToleranceAfter = .zero

        let image: CGImage?

        do {
            image = try copyCGImage(at: time, actualTime: nil)
        } catch let error {
            restoreState()
            handler(error, nil)
            return
        }

        restoreState()
        handler(nil, image)
    }
}

// MARK: - Debug

extension AVPlayerItemStatus: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .unknown: return "AVPlayerItemStatus.unknown"
        case .failed: return "AVPlayerItemStatus.failed"
        case .readyToPlay: return "AVPlayerItemStatus.readyToPlay"
        }
    }
}

extension AVPlayerStatus: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .unknown: return "AVPlayerStatus.unknown"
        case .failed: return "AVPlayerStatus.failed"
        case .readyToPlay: return "AVPlayerStatus.readyToPlay"
        }
    }
}

extension AVPlayerLooperStatus: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .unknown: return "AVPlayerLooperStatus.unknown"
        case .cancelled: return "AVPlayerLooperStatus.cancelled"
        case .failed: return "AVPlayerLooperStatus.failed"
        case .ready: return "AVPlayerLooperStatus.ready"
        }
    }
}

extension AVPlayerTimeControlStatus: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .paused: return "AVPlayerTimeControlStatus.paused"
        case .playing: return "AVPlayerTimeControlStatus.playing"
        case .waitingToPlayAtSpecifiedRate: return "AVPlayerTimeControlStatus.waitingToPlayAtSpecifiedRate"
        }
    }
}
