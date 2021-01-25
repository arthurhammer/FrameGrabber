import AVFoundation

/// Performs "smooth seeking" on an AVPlayer.
///
/// - See also: [QA1820](https://developer.apple.com/library/content/qa/qa1820/_index.html).
/// - See also: [AVFoundation Release Notes for iOS 5](https://developer.apple.com/library/content/releasenotes/AudioVideo/RN-AVFoundation/index.html#//apple_ref/doc/uid/TP40010717-CH1-DontLinkElementID_6).
class PlayerSeeker {

    struct Target {
        let time: CMTime
        let toleranceBefore: CMTime
        let toleranceAfter: CMTime
    }

    let player: AVPlayer

    /// True if the receiver is performing a seek.
    var isSeeking: Bool {
        currentSeek != nil
    }

    /// The overall time the receiver is seeking towards.
    var targetTime: CMTime? {
        (nextSeek ?? currentSeek)?.time
    }

    /// The seek currently in progress.
    private(set) var currentSeek: Target?

    /// The seek that starts when the current seek finishes.
    private(set) var nextSeek: Target?

    init(player: AVPlayer) {
        self.player = player
    }

    func cancelPendingSeeks() {
        player.currentItem?.cancelPendingSeeks()
    }

    /// Smoothly seeks to the given time.
    ///
    /// Lets pending seeks finish before new ones are started when invoked in succession
    /// (such as from a `UISlider`). When the current seek finishes, the latest of the
    /// enqueued ones is started. To start a seek immediately, use `directlySeek`.
    func smoothlySeek(to time: CMTime, toleranceBefore: CMTime = .zero, toleranceAfter: CMTime = .zero) {
        let target = Target(time: time, toleranceBefore: toleranceBefore, toleranceAfter: toleranceAfter)
        smoothlySeek(to: target)
    }

    func smoothlySeek(to target: Target) {
        guard target.time != player.currentTime() else { return }

        nextSeek = target

        if !isSeeking {
            if player.rate > 0 {
                player.pause()
            }

            startNextSeek()
        }
    }

    func directlySeek(to time: CMTime, toleranceBefore: CMTime = .zero, toleranceAfter: CMTime = .zero) {
        cancelPendingSeeks()

        if player.rate > 0 {
            player.pause()
        }

        nextSeek = Target(time: time, toleranceBefore: toleranceBefore, toleranceAfter: toleranceAfter)
        startNextSeek()
    }

    private func startNextSeek() {
        guard let next = nextSeek else { return }

        currentSeek = next
        nextSeek = nil

        player.seek(to: next) { [weak self] finished in
            self?.didFinishCurrentSeek(wasCancelled: !finished)
        }
    }

    private func didFinishCurrentSeek(wasCancelled: Bool) {
        currentSeek = nil

        let shouldContinue = !wasCancelled && (nextSeek != nil)

        if shouldContinue {
            startNextSeek()
        } else {
            didFinishAllSeeks()
        }
    }

    private func didFinishAllSeeks() {
        currentSeek = nil
        nextSeek = nil
    }
}

extension AVPlayer {
    func seek(to target: PlayerSeeker.Target, completionHandler: @escaping (Bool) -> ()) {
        seek(to: target.time,
             toleranceBefore: target.toleranceBefore,
             toleranceAfter: target.toleranceAfter,
             completionHandler: completionHandler)
    }
}
