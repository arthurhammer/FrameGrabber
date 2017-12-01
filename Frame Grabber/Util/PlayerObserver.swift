import AVKit

protocol PlayerObserverDelegate: class {
    func didUpdateStatus(_ status: AVPlayerStatus, of player: AVPlayer)
    func didUpdateTimeControlStatus(_ status: AVPlayerTimeControlStatus, of player: AVPlayer)
    func didUpdateRate(_ rate: Float, of player: AVPlayer)
    func didUpdateReasonForWaitingToPlay(_ reason: AVPlayer.WaitingReason?, of player: AVPlayer)
    func didUpdateCurrentItem(_ item: AVPlayerItem?, of player: AVPlayer)
    func didPeriodicUpdate(at time: CMTime, for player: AVPlayer)
    func didUpdateStatus(_ status: AVPlayerItemStatus, ofCurrentPlayerItem item: AVPlayerItem)
}

extension PlayerObserverDelegate {
    func didUpdateStatus(_ status: AVPlayerStatus, of player: AVPlayer) {}
    func didUpdateTimeControlStatus(_ status: AVPlayerTimeControlStatus, of player: AVPlayer) {}
    func didUpdateRate(_ rate: Float, of player: AVPlayer) {}
    func didUpdateReasonForWaitingToPlay(_ reason: AVPlayer.WaitingReason?, of player: AVPlayer) {}
    func didUpdateCurrentItem(_ item: AVPlayerItem?, of player: AVPlayer) {}
    func didPeriodicUpdate(at time: CMTime, for player: AVPlayer) {}
    func didUpdateStatus(_ status: AVPlayerItemStatus, ofCurrentPlayerItem item: AVPlayerItem) {}
}

/// Observes an `AVPlayer` for updates.
class PlayerObserver {

    /// Setting the delegate will send initial values.
    weak var delegate: PlayerObserverDelegate? {
        didSet {
            stopObserving()
            if delegate != nil {
                observe()
            }
        }
    }

    let player: AVPlayer

    init(player: AVPlayer, periodicTimeObservationInterval: TimeInterval = 1/30.0) {
        self.player = player
        self.periodicTimeObservationInterval = CMTime(seconds: periodicTimeObservationInterval)
    }

    deinit {
        stopObserving()
    }

    private let periodicTimeObservationInterval: CMTime

    // Player
    private var periodicTimeObserver: Any?
    private var statusObserver: NSKeyValueObservation?
    private var timeControlStatusObserver: NSKeyValueObservation?
    private var rateObserver: NSKeyValueObservation?
    private var reasonForWaitingToPlayObserver: NSKeyValueObservation?
    private var currentItemObserver: NSKeyValueObservation?
    // Player Item
    private var currentItemStatusObserver: NSKeyValueObservation?
}

// MARK: Private

private extension PlayerObserver {

    func observe() {
        stopObserving()
        
        statusObserver = player.observe(\.status, options: .initial) { [weak self] player, _ in
            self?.delegate?.didUpdateStatus(player.status, of: player)
        }

        timeControlStatusObserver = player.observe(\.timeControlStatus, options: .initial) { [weak self] player, _ in
            self?.delegate?.didUpdateTimeControlStatus(player.timeControlStatus, of: player)
        }

        rateObserver = player.observe(\.rate, options: .initial) { [weak self] player, _ in
            self?.delegate?.didUpdateRate(player.rate, of: player)
        }

        reasonForWaitingToPlayObserver = player.observe(\.reasonForWaitingToPlay, options: .initial) { [weak self] player, _ in
            self?.delegate?.didUpdateReasonForWaitingToPlay(player.reasonForWaitingToPlay, of: player)
        }

        currentItemObserver = player.observe(\.currentItem, options: .initial) { [weak self] player, _ in
            self?.delegate?.didUpdateCurrentItem(player.currentItem, of: player)
        }

        currentItemStatusObserver = player.observe(\.currentItem?.status, options: .initial) { [weak self] player, _ in
            guard let item = player.currentItem else { return }
            self?.delegate?.didUpdateStatus(item.status, ofCurrentPlayerItem: item)
        }

        periodicTimeObserver = player.addPeriodicTimeObserver(forInterval: periodicTimeObservationInterval, queue: nil) { [weak self] time in
            guard let this = self else { return }
            this.delegate?.didPeriodicUpdate(at: time, for: this.player)
        }
    }

    func stopObserving() {
        statusObserver = nil
        timeControlStatusObserver = nil
        rateObserver = nil
        currentItemObserver = nil
        reasonForWaitingToPlayObserver = nil
        currentItemStatusObserver = nil

        if let timeObserver = periodicTimeObserver {
            player.removeTimeObserver(timeObserver)
            periodicTimeObserver = nil
        }
    }
}
