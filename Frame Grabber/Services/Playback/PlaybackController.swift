import AVFoundation
import UIKit.UIApplication
import Combine

/// Manages playback for assets.
class PlaybackController {

    let player: AVPlayer

    var asset: AVAsset? {
        didSet {
            seeker.cancelPendingSeeks()
            player.replaceCurrentItem(with: asset.map(AVPlayerItem.init))
        }
    }

    @Published private(set) var status: AVPlayer.PlayerAndItemStatus = .unknown
    @Published private(set) var timeControlStatus: AVPlayer.TimeControlStatus = .paused
    @Published private(set) var isPlaying: Bool = false
    @Published private(set) var currentTime: CMTime = .zero
    @Published private(set) var duration: CMTime = .zero

    // MARK: - Private Properties

    private let seeker: PlayerSeeker
    private let audioSession: AVAudioSession
    private let notificationCenter: NotificationCenter
    private var bindings = Set<AnyCancellable>()

    init(asset: AVAsset? = nil, audioSession: AVAudioSession = .sharedInstance(), notificationCenter: NotificationCenter = .default) {
        self.player = AVPlayer(playerItem: asset.map(AVPlayerItem.init))
        self.player.actionAtItemEnd = .pause
        self.seeker = PlayerSeeker(player: self.player)
        self.audioSession = audioSession
        self.notificationCenter = notificationCenter

        bindPlayer()
        configureAudioSession()
    }

    // MARK: - Playback

    func playOrPause() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }

    func play() {
        guard !isPlaying else { return }

        seekToStartIfNecessary()
        player.play()
    }

    func pause() {
        guard isPlaying else { return }
        player.pause()
    }

    func step(byCount count: Int) {
        pause()
        player.currentItem?.step(byCount: count)
    }

    // MARK: - Seeking

    func smoothlySeek(to time: CMTime) {
        seeker.smoothlySeek(to: time)
    }

    func directlySeek(to time: CMTime) {
        seeker.directlySeek(to: time)
    }

    private func seekToStartIfNecessary() {
        guard let item = player.currentItem,
              item.currentTime() >= item.duration else { return }

        directlySeek(to: .zero)
    }

    // MARK: - Handling Audio Session

    private func configureAudioSession() {
        try? audioSession.setCategory(.ambient)
        notificationCenter.addObserver(self, selector: #selector(updateAudioSession), name: AVAudioSession.silenceSecondaryAudioHintNotification, object: audioSession)
        notificationCenter.addObserver(self, selector: #selector(updateAudioSession), name: UIApplication.willResignActiveNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(updateAudioSession), name: UIApplication.didBecomeActiveNotification, object: nil)
        updateAudioSession()
    }

    @objc private func updateAudioSession() {
        player.isMuted = audioSession.secondaryAudioShouldBeSilencedHint
    }

    // MARK: - Binding Player

    private func bindPlayer() {
        player.playerAndItemStatusPublisher()
            .assignWeak(to: \.status, on: self)
            .store(in: &bindings)

        player.publisher(for: \.timeControlStatus)
            .removeDuplicates()
            .assignWeak(to: \.timeControlStatus, on: self)
            .store(in: &bindings)

        player.publisher(for: \.rate)
            .map { $0 != 0 }
            .removeDuplicates()
            .assignWeak(to: \.isPlaying, on: self)
            .store(in: &bindings)

        player.periodicTimePublisher()
            .assignWeak(to: \.currentTime, on: self)
            .store(in: &bindings)

        player.publisher(for: \.currentItem?.duration)
            .replaceNil(with: .zero)
            .removeDuplicates()
            .assignWeak(to: \.duration, on: self)
            .store(in: &bindings)
    }
}
