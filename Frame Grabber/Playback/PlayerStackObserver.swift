import AVKit

protocol PlayerStackObserverDelegate: class {
    func didUpdateStatus(_ status: PlayerStackStatus, of stack: PlayerStack)
    func didPeriodicUpdate(at time: CMTime)
}

/// Observes a player stack and its components for status updates.
class PlayerStackObserver {

    /// The delegate will be notified immediately (possibly multiple times) with the current status.
    weak var delegate: PlayerStackObserverDelegate? {
        didSet {
            guard delegate != nil else {
                stopObserving()
                return
            }

            observe()
        }
    }

    let stack: PlayerStack

    init(stack: PlayerStack, periodicTimeObservationInterval: TimeInterval = 1/25.0) {
        self.stack = stack
        self.periodicTimeObservationInterval = CMTime(interval: periodicTimeObservationInterval)
    }

    deinit {
        stopObserving()
    }

    private var isObserving = false
    private let periodicTimeObservationInterval: CMTime
    private var playerStatusObserver: NSKeyValueObservation?
    private var looperStatusObserver: NSKeyValueObservation?
    private var playerItemsStatusObservers = [NSKeyValueObservation]()
    private var playerTimeObserver: Any?
}

// MARK: Private

// There's not much sample code or guides how to handle the status of `AVPlayerLooper` with `AVPlayerItem`, here's my take:
//
// `AVPlayerLooper` manages several copies of the initial `AVPlayerItem`.
// To observe the player item status we need to observe the *current item* of the player which is changing with every loop (not the initial template item).
// To do that, we can observe *all* of the looper's items and filter for the current one in the handler.
// Observation of the item's should not start before the looper is ready as `loopingPlayerItems` is not guaranteed to have been initialized yet (this is the case for streaming player items, e.g. from iCloud)
// Important: Use `initial` for KVO updates.

private extension PlayerStackObserver {

    func observe() {
        guard !isObserving else { return }
        isObserving = true

        // Player
        playerStatusObserver = stack.player.observe(\.status, options: .initial) { [weak self] player, _ in
            self?.didUpdateStatus()
        }

        // Looper
        looperStatusObserver = stack.looper.observe(\.status, options: .initial) { [weak self] looper, _ in
            // Notifiy before setting up items
            self?.didUpdateStatus()

            if case .ready = looper.status {
                // Player Items
                self?.observeLoopingPlayerItems(looper.loopingPlayerItems)
            }
        }

        // Periodically for player
        playerTimeObserver = stack.player.addPeriodicTimeObserver(forInterval: periodicTimeObservationInterval, queue: nil) { [weak self] time in
            self?.delegate?.didPeriodicUpdate(at: time)
        }
    }

    func observeLoopingPlayerItems(_ items: [AVPlayerItem]) {
        playerItemsStatusObservers = []
        items.forEach(observe)
    }

    func observe(item: AVPlayerItem) {
        let observer = item.observe(\.status, options: .initial) { [weak self] item, _ in
            guard item == self?.stack.currentItem else { return }
            self?.didUpdateStatus()
        }

        playerItemsStatusObservers.append(observer)
    }

    func stopObserving() {
        isObserving = false

        playerStatusObserver = nil
        looperStatusObserver = nil
        playerItemsStatusObservers = []

        if let timeObserver = playerTimeObserver {
            stack.player.removeTimeObserver(timeObserver)
            playerTimeObserver = nil
        }
    }

    func didUpdateStatus() {
        delegate?.didUpdateStatus(stack.status, of: stack)
    }
}
