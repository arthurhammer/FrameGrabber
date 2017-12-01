import AVKit

extension AVPlayer {

    var isPlaying: Bool {
        return rate != 0
    }

    func playOrPause() {
        rate = isPlaying ? 0 : 1
    }

    /// True if the current item supports stepping forward and backward.
    /// Status changes with the current item.
    /// Returns `false` prior to an item being ready to play.
    var canStep: Bool {
        guard let item = currentItem, item.status == .readyToPlay else { return false }
        return item.canStepBackward && item.canStepForward
    }

    func stepForward() {
        step(by: 1)
    }

    func stepBackward() {
        step(by: -1)
    }

    func step(by count: Int) {
        pause()
        currentItem?.step(byCount: count)
    }
}

extension CMTime {
    static let zero = kCMTimeZero

    init(seconds: Double, preferredTimeScale: CMTimeScale = CMTimeScale(NSEC_PER_SEC)) {
        self.init(seconds: seconds, preferredTimescale: preferredTimeScale)
    }
}

extension AVAssetImageGenerator {

    /// Note: When the method returns `requestedTimeToleranceAfter`/`requestedTimeToleranceBefore` will be `kCMTimeZero`.
    func copyCGImage(atExactTime time: CMTime, handler: (Error?, CGImage?) -> ()) {
        requestedTimeToleranceBefore = .zero
        requestedTimeToleranceAfter = .zero

        let image: CGImage?

        do {
            image = try copyCGImage(at: time, actualTime: nil)
        } catch let error {
            handler(error, nil)
            return
        }

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
