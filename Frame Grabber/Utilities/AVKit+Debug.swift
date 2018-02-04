import AVKit

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
