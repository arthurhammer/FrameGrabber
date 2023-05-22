import AVFoundation
import Combine
import SampleTimeIndexer
import Utility
import UIKit

/// Manages playback for assets.
class PlaybackController {

    let player: AVPlayer
    
    @Published var asset: AVAsset? {
        didSet {
            seeker.cancelPendingSeeks()
            player.replaceCurrentItem(with: asset.map(AVPlayerItem.init))
            indexSampleTimes()
        }
    }

    @Published private(set) var status = AVPlayer.PlayerAndItemStatus.unknown
    @Published private(set) var timeControlStatus = AVPlayer.TimeControlStatus.paused
    @Published private(set) var isPlaying = false
    @Published private(set) var duration = CMTime.zero
    @Published var defaultRate: Float = 1 {
        didSet { updateDefaultRate() }
    }
    
    /// The current playback time of `player`.
    @Published private(set) var currentPlaybackTime = CMTime.zero
    
    /// The start time of the sample that corresponds to the current playback time.
    ///
    /// The controller indexes the asset's samples in the background. The sample times are therefore
    /// not immediately available. In addition, indexing can fail. In these cases, returns `nil`.
    ///
    /// The publisher emits values whenever the current playback time changes. If sample times are
    /// not available, repeatedly emits `nil`.
    @Published private(set) var currentSampleTime: CMTime?
    
    /// TODO: This is a quick hack.
    @Published private(set) var _isIndexingSampleTimes: Bool = false

    // MARK: - Private Properties

    private let seeker: PlayerSeeker
    private let sampleIndexer: SampleTimeIndexer
    private var sampleTimes: SampleTimes?
    private var bindings = Set<AnyCancellable>()
    
    private let interval = CMTime(seconds: 1/60.0, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
    private let audioSession: AVAudioSession = .sharedInstance()
    private let notificationCenter: NotificationCenter = .default

    init(player: AVPlayer = .init(), sampleIndexer: SampleTimeIndexer = SampleTimeIndexerImpl()) {
        self.player = player
        self.player.actionAtItemEnd = .pause
        self.seeker = PlayerSeeker(player: player)
        self.sampleIndexer = sampleIndexer

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

    @objc func pause() {
        guard isPlaying else { return }
        player.pause()
    }

    func step(byCount count: Int) {
        pause()
        player.currentItem?.step(byCount: count)
    }

    // MARK: - Seeking

    func smoothlySeek(to time: CMTime) {
        seeker.smoothlySeek(to: seekTime(for: time))
    }

    func directlySeek(to time: CMTime) {
        seeker.directlySeek(to: seekTime(for: time))
    }

    private func seekToStartIfNecessary() {
        guard let item = player.currentItem,
              item.currentTime() >= item.duration else { return }

        directlySeek(to: .zero)
    }

    // MARK: - Handling Audio Session

    private func configureAudioSession() {
        try? audioSession.setCategory(.ambient)
        notificationCenter.addObserver(self, selector: #selector(pause), name: UIApplication.didEnterBackgroundNotification, object: nil)
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

        player.periodicTimePublisher(forInterval: interval)
            .assignWeak(to: \.currentPlaybackTime, on: self)
            .store(in: &bindings)

        player.periodicTimePublisher(forInterval: interval)
            .map { [weak self] in
                self?.sampleTime(for: $0)
            }
            .assignWeak(to: \.currentSampleTime, on: self)
            .store(in: &bindings)

        player.publisher(for: \.currentItem?.duration)
            .replaceNil(with: .zero)
            .removeDuplicates()
            .assignWeak(to: \.duration, on: self)
            .store(in: &bindings)
    }
    
    private func updateDefaultRate() {
        if #available(iOS 16.0, *) {
            player.defaultRate = defaultRate
            if isPlaying {
                player.play()  // Adopt new rate if already playing.
            }
        }
    }
    
    // MARK: - Sample-Level Timing

    /// The time of the sample at `playbackTime` if `playbackTime` is smaller or equal to the last
    /// sample. Otherwise, `playbackTime` itself.
    ///
    /// When seeking beyond the last sample, do not snap to the last sample or the player won't
    /// be able to reach the end of the playback via seeking.
    private func seekTime(for playbackTime: CMTime) -> CMTime {
        guard let sampleTime = sampleTime(for: playbackTime),
              let lastSample = sampleTimes?.values.last?.presentationTimeStamp else { return playbackTime }
        
        return (playbackTime > lastSample) ? playbackTime : sampleTime
    }
 
    private func sampleTime(for playbackTime: CMTime) -> CMTime? {
        sampleTimes?.sampleTiming(for: playbackTime)?.presentationTimeStamp
    }
    
    func relativeFrameNumber(for playbackTime: CMTime) -> Int? {
        guard let index = sampleTimes?.sampleTimingIndexInSecond(for: playbackTime) else {
            return nil
        }
        return index + 1
    }
    
    private func indexSampleTimes() {
        currentSampleTime = nil
        sampleTimes = nil
        sampleIndexer.cancel()
        
        guard let asset else { return }
        
        // TODO: Currently resides on the assumption that `asset` is set only once. If it isn't, the
        // of completion handlers and the value of this flag are not guaranteed.
        _isIndexingSampleTimes = true
        
        sampleIndexer.indexTimes(for: asset) { [weak self] result in
            DispatchQueue.main.async {
                self?._isIndexingSampleTimes = false
                self?.sampleTimes = try? result.get()  // Ignoring errors
                self?.currentSampleTime = self?.sampleTime(for: self?.currentPlaybackTime ?? .zero)
            }
        }
    }
}
