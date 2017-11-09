import AVKit

protocol PlayerDelegate: class {
    func didUpdateStatus(_ status: VideoStatus, of video: Video)
    func didUpdateStatus(_ status: AVPlayerItemStatus, of playerItem: AVPlayerItem)
    func didUpdateStatus(_ status: AVPlayerStatus, of player: Player)
    func didPeriodicUpdate(at time: CMTime)
}

/// A video player.
class Player: AVPlayer {

    // TODO: .initial in observing and re-starting observation can be faulty.
    //       also: player status/item might be important for observation. dont restart if player failed or sth.

    weak var delegate: PlayerDelegate? {
        didSet {
            // TODO
            if delegate != nil && currentItem != nil {
                startObserving()
            } else {
                stopObserving()
            }
        }
    }

    var video: Video? {
        didSet {
            oldValue?.cancelLoadingPlayerItem()
            currentItem = nil
            loadPlayerItem()
        }
    }

    override private(set) var currentItem: AVPlayerItem? {
        get {
            return super.currentItem
        }
        set {
            stopObserving()
            replaceCurrentItem(with: newValue)

            if delegate != nil && currentItem != nil {
                startObserving()
            }
        }
    }

    var loops = true

    var canStepBackwardAndForward: Bool {
        guard let playerItem = currentItem else { return false }
        return playerItem.canStepBackward && playerItem.canStepForward
    }

    // TODO: this is useless since never called.
    deinit {
        print("deinit player")
        video?.cancelLoadingPlayerItem()
        stopObserving()
    }

    func seekToStart() {
        seek(to: kCMTimeZero)
    }

    func step(by count: Int) {
        pause()
        currentItem?.step(byCount: count)
    }

    func reset() {
        return ()

        // TODO
        pause()
        seekToStart()
        currentItem = nil // video?.playerItem  // todo: or nil? out of sync video <-> player
    }

    func startObserving() {
        startObservingPlayerStatus()
        startObservingPlayerItemStatus()
        startObservingPeriodicTime()
        startObservingPlayerItemDidPlayToEndTime()
    }

    func stopObserving() {
        stopObservingPlayerStatus()
        stopObservingPlayerItemStatus()
        stopObservingPeriodicTime()
        stopObservingPlayerItemDidPlayToEndTime()
    }


    private var playerStatusObserver: NSKeyValueObservation?
    private var playerItemStatusObserver: NSKeyValueObservation?
    private var playerPeriodicObserver: Any?

    private let periodicObservationInterval: TimeInterval = 0.08
}

// MARK: - Private

private extension Player {

    func loop() {
        guard loops else { return }
        seekToStart()
        play()
    }

    func loadPlayerItem() {
        video?.loadPlayerItem { [weak self] video, status in

            if case let .loaded(playerItem) = status {
                self?.currentItem = playerItem
            }

            self?.delegate?.didUpdateStatus(status, of: video)
        }
    }

    // MARK: Observing


    func startObservingPlayerStatus() {
        stopObservingPlayerStatus()

        // Note: In contrast with the old KVO API, this new Swift 4 KVO API does not
        //       always deliver changed values in the change dictionary for some reason.
        //       Instead for now, we use the observed objects *current* value even though
        //       it might not be the same as reported in the change dictionary.
        //       Same applies below.
        playerStatusObserver = observe(\.status, options: .initial) { [weak self] observed, change in
            self?.delegate?.didUpdateStatus(observed.status, of: observed)
        }
    }

    func stopObservingPlayerStatus() {
        playerStatusObserver = nil
    }

    func startObservingPlayerItemStatus() {
        stopObservingPlayerItemStatus()

        playerItemStatusObserver = currentItem?.observe(\.status, options: .initial) { [weak self] observed, change in
            self?.delegate?.didUpdateStatus(observed.status, of: observed)
        }
    }

    func stopObservingPlayerItemStatus() {
        playerItemStatusObserver = nil
    }

    func startObservingPeriodicTime() {
        stopObservingPeriodicTime()

        let interval = CMTime(seconds: periodicObservationInterval, preferredTimescale: CMTimeScale(NSEC_PER_SEC))

        playerPeriodicObserver = addPeriodicTimeObserver(forInterval: interval, queue: nil) { [weak self] time in
            self?.delegate?.didPeriodicUpdate(at: time)
        }
    }

    func stopObservingPeriodicTime() {
        guard let periodicObserver = playerPeriodicObserver else { return }
        removeTimeObserver(periodicObserver)
        playerPeriodicObserver = nil
    }

    func startObservingPlayerItemDidPlayToEndTime() {
        stopObservingPlayerItemDidPlayToEndTime()

        guard let playerItem = currentItem else { return }

        let notification = NSNotification.Name.AVPlayerItemDidPlayToEndTime

        NotificationCenter.default.addObserver(forName: notification, object: playerItem, queue: nil) { [weak self] notification in
            // Main thread not guaranteed
            DispatchQueue.main.async {
                self?.loop()
            }
        }
    }

    func stopObservingPlayerItemDidPlayToEndTime() {
        guard let playerItem = currentItem else { return }

        let notification = NSNotification.Name.AVPlayerItemDidPlayToEndTime
        NotificationCenter.default.removeObserver(self, name: notification, object: playerItem)
    }
}
