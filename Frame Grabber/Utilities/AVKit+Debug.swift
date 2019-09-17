import AVKit

extension AVPlayerItem.Status: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .unknown: return "AVPlayerItem.Status.unknown"
        case .failed: return "AVPlayerItem.Status.failed"
        case .readyToPlay: return "AVPlayerItem.Status.readyToPlay"
        @unknown default: return "Unknown AVPlayerItem.Status"
        }
    }
}

extension AVPlayer.Status: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .unknown: return "AVPlayer.Status.unknown"
        case .failed: return "AVPlayer.Status.failed"
        case .readyToPlay: return "AVPlayer.Status.readyToPlay"
        @unknown default: return "Unknown AVPlayer.Status"
        }
    }
}

extension AVPlayerLooper.Status: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .unknown: return "AVPlayerLooper.Status.unknown"
        case .cancelled: return "AVPlayerLooper.Status.cancelled"
        case .failed: return "AVPlayerLooper.Status.failed"
        case .ready: return "AVPlayerLooper.Status.ready"
        @unknown default: return "Unknown AVPlayerLooper.Status"
        }
    }
}

extension AVPlayer.TimeControlStatus: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .paused: return "AVPlayer.TimeControlStatus.paused"
        case .playing: return "AVPlayer.TimeControlStatus.playing"
        case .waitingToPlayAtSpecifiedRate: return "AVPlayer.TimeControlStatus.waitingToPlayAtSpecifiedRate"
        @unknown default: return "Unknown AVPlayer.TimeControlStatus"
        }
    }
}

extension AVPlayer.WaitingReason: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .evaluatingBufferingRate: return "AVPlayer.WaitingReason.evaluatingBufferingRate"
        case .noItemToPlay: return "AVPlayer.WaitingReason.noItemToPlay"
        case .toMinimizeStalls: return "AVPlayer.WaitingReason.toMinimizeStalls"
        default: return "Unknown AVPlayer.WaitingReason"
        }
    }
}
