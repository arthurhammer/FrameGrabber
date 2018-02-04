import AVKit

protocol PlayerObserverDelegate: class {
    func player(_ player: AVPlayer, didUpdateStatus status: AVPlayerStatus)
    func player(_ player: AVPlayer, didPeriodicUpdateAtTime time: CMTime)
    func player(_ player: AVPlayer, didUpdateTimeControlStatus status: AVPlayerTimeControlStatus)
    func player(_ player: AVPlayer, didUpdateRate rate: Float)
    func player(_ player: AVPlayer, didUpdateReasonForWaitingToPlay status: AVPlayer.WaitingReason?)
    func player(_ player: AVPlayer, didUpdateCurrentPlayerItem item: AVPlayerItem?)

    func currentPlayerItem(_ playerItem: AVPlayerItem, didUpdateStatus status: AVPlayerItemStatus)
    func currentPlayerItem(_ playerItem: AVPlayerItem, didUpdateDuration duration: CMTime)
}

extension PlayerObserverDelegate {
    func player(_ player: AVPlayer, didUpdateStatus status: AVPlayerStatus) {}
    func player(_ player: AVPlayer, didPeriodicUpdateAtTime time: CMTime) {}
    func player(_ player: AVPlayer, didUpdateTimeControlStatus status: AVPlayerTimeControlStatus) {}
    func player(_ player: AVPlayer, didUpdateRate rate: Float) {}
    func player(_ player: AVPlayer, didUpdateReasonForWaitingToPlay status: AVPlayer.WaitingReason?) {}
    func player(_ player: AVPlayer, didUpdateCurrentPlayerItem item: AVPlayerItem?) {}

    func currentPlayerItem(_ playerItem: AVPlayerItem, didUpdateStatus status: AVPlayerItemStatus) {}
    func currentPlayerItem(_ playerItem: AVPlayerItem, didUpdateDuration duration: CMTime) {}
}

class PlayerObserver {

    /// Initial values are sent when the delegate is set
    weak var delegate: PlayerObserverDelegate? {
        didSet {
            stopObserving()
            if delegate != nil {
                startObserving()
            }
        }
    }

    let player: AVPlayer

    private let periodicTimeObservationInterval: CMTime
    private var timeObserver: Any?
    private lazy var kvoOptions: NSKeyValueObservingOptions = .initial
    private lazy var kvoObservers = [NSKeyValueObservation]()

    init(player: AVPlayer, periodicTimeObservationInterval: TimeInterval = 1/30.0) {
        self.player = player
        self.periodicTimeObservationInterval = CMTime(seconds: periodicTimeObservationInterval)
    }

    deinit {
        stopObserving()
    }
}

private extension PlayerObserver {

    func startObserving() {
        stopObserving()

        timeObserver = player.addPeriodicTimeObserver(forInterval: periodicTimeObservationInterval, queue: nil) { [weak self] time in
            guard let this = self else { return }
            this.delegate?.player(this.player, didPeriodicUpdateAtTime: time)
        }

        add(player.observe(\.status, options: kvoOptions) { [weak self] player, _ in
            self?.delegate?.player(player, didUpdateStatus: player.status)
        })

        add(player.observe(\.timeControlStatus, options: kvoOptions) { [weak self] player, _ in
            self?.delegate?.player(player, didUpdateTimeControlStatus: player.timeControlStatus)
        })

        add(player.observe(\.rate, options: kvoOptions) { [weak self] player, _ in
            self?.delegate?.player(player, didUpdateRate: player.rate)
        })

        add(player.observe(\.reasonForWaitingToPlay, options: kvoOptions) { [weak self] player, _ in
            self?.delegate?.player(player, didUpdateReasonForWaitingToPlay: player.reasonForWaitingToPlay)
        })

        add(player.observe(\.currentItem, options: kvoOptions) { [weak self] player, _ in
            self?.delegate?.player(player, didUpdateCurrentPlayerItem: player.currentItem)
        })

        add(player.observe(\.currentItem?.status, options: kvoOptions) { [weak self] player, _ in
            guard let item = player.currentItem else { return }
            self?.delegate?.currentPlayerItem(item, didUpdateStatus: item.status)
        })

        add(player.observe(\.currentItem?.duration, options: kvoOptions) { [weak self] player, _ in
            guard let item = player.currentItem else { return }
            self?.delegate?.currentPlayerItem(item, didUpdateDuration: item.duration)
        })
    }

    func stopObserving() {
        if let observer = timeObserver {
            player.removeTimeObserver(observer)
            timeObserver = nil
        }

        kvoObservers = []
    }

    func add(_ observer: NSKeyValueObservation) {
        kvoObservers.append(observer)
    }
}
