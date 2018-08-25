import AVKit

struct SeekInfo {
    let time: CMTime
    let toleranceBefore: CMTime
    let toleranceAfter: CMTime
}

/// Implements "smooth seeking" as described in QA1820.
/// - Note: [QA1820](https://developer.apple.com/library/content/qa/qa1820/_index.html),
///         see also: [AV Foundation Release Notes for iOS 5](https://developer.apple.com/library/content/releasenotes/AudioVideo/RN-AVFoundation/index.html#//apple_ref/doc/uid/TP40010717-CH1-DontLinkElementID_6).
class PlayerSeeker {

    private let player: AVPlayer

    /// True if the seeker is performing a seek.
    /// Does not consider seeks directly started on the receiver's player.
    var isSeeking: Bool {
        return currentSeek != nil
    }

    /// The overall time the player is seeking towards.
    var finalSeekTime: CMTime? {
        return (nextSeek ?? currentSeek)?.time
    }

    /// The seek currently in progress.
    private(set) var currentSeek: SeekInfo?

    /// The seek that starts when `currentSeek` finishes.
    private(set) var nextSeek: SeekInfo?

    init(player: AVPlayer) {
        self.player = player
    }

    func cancelPendingSeeks() {
        player.currentItem?.cancelPendingSeeks()
    }

    /// "Smoothly" seeks to the given time by letting pending seeks finish before new ones
    /// are started when invoked in succession (such as from a `UISlider`). When the
    /// current seek finishes, the latest of the enqueued ones is started.
    ///
    /// To start a seek immediately cancel pending seeks explicitly prior to calling this.
    ///
    /// - Note: [QA1820](https://developer.apple.com/library/content/qa/qa1820/_index.html)
    func smoothlySeek(to time: CMTime, toleranceBefore: CMTime = .zero, toleranceAfter: CMTime = .zero) {
        let info = SeekInfo(time: time, toleranceBefore: toleranceBefore, toleranceAfter: toleranceAfter)
        smoothlySeek(with: info)
    }

    func smoothlySeek(with info: SeekInfo) {
        guard info.time != player.currentTime() else { return }

        nextSeek = info

        if !isSeeking {
            if player.rate > 0 {
                player.pause()
            }
            startNextSeek()
        }
    }

    private func startNextSeek() {
        guard let next = nextSeek else { fatalError("No next seek to start") }

        currentSeek = next
        nextSeek = nil

        player.seek(with: currentSeek!) { [weak self] finished in
            self?.didFinishCurrentSeek(wasCancelled: !finished)
        }
    }

    private func didFinishCurrentSeek(wasCancelled: Bool) {
        currentSeek = nil

        let continueSeeking = !wasCancelled && (nextSeek != nil)

        if continueSeeking {
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
    func seek(with info: SeekInfo, completionHandler: @escaping (Bool) -> ()) {
        seek(to: info.time,
             toleranceBefore: info.toleranceBefore,
             toleranceAfter: info.toleranceAfter,
             completionHandler: completionHandler)
    }
}
