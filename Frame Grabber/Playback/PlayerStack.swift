import AVKit

enum PlayerStackStatus {
    /// One or more components are not ready.
    case notReady
    /// One or more components failed. Check the components for details about the error.
    case failed
    /// All components are ready to play.
    case readyToPlay
}

extension PlayerStack {
    var status: PlayerStackStatus {
        switch (currentItem?.status, looper.status, player.status) {
        case (.failed?, _, _), (_, .failed, _), (_, _, .failed):
            return .failed
        case (.readyToPlay?, .ready, .readyToPlay):
            return .readyToPlay
        default:
            return .notReady
        }
    }
}

/// Components for looped playback for a player item.
class PlayerStack {
    let templateItem: AVPlayerItem
    let player: AVQueuePlayer
    let looper: AVPlayerLooper

    var currentItem: AVPlayerItem? {
        return player.currentItem
    }

    init(loopingTemplateItem: AVPlayerItem) {
        self.templateItem = loopingTemplateItem
        self.player = AVQueuePlayer()
        self.looper = AVPlayerLooper(player: self.player, templateItem: self.templateItem)
    }
}
