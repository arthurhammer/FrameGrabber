import AVKit

// TODO: Causes reference cycle! ditch and move on

class LoopingPlayer: AVQueuePlayer {

    private var looper: AVPlayerLooper!

    required init(templateItem: AVPlayerItem) {
        super.init()
        looper = AVPlayerLooper(player: self, templateItem: templateItem)
        play()
    }
}

typealias PlayerManagerDelegate = PlayerObserverDelegate

// TODO: Manager, or player, or !?!?
// doees not allow to change player? only one?
class PlayerManager {

    weak var delegate: PlayerManagerDelegate? {
        didSet {
            observer.delegate = delegate
        }
    }

    var player: AVPlayer {
        return observer.player
    }

    // HM. player item, or player, or!?!
    init(templateItem: AVPlayerItem) {
        let player = AVQueuePlayer()
        self.observer = PlayerObserver(player: player)
        self.looper = AVPlayerLooper(player: player, templateItem: templateItem)
        player.play()
    }

    private let looper: AVPlayerLooper
    private let observer: PlayerObserver
}
