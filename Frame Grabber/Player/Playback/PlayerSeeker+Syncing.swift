import AVKit

// TODO: Documentation

extension PlayerSeeker {

    /// Utility.
    /// Cancels pending seeks and starts a new seek to the final seek time with the given
    /// tolerance. This can be used in certain situations to finish seeking faster, e.g.
    /// by using higher tolerances than the pending seeks and/or by replacing two pending
    /// seeks (current and next) with a single final seek.
    func seekToFinalTime(withToleranceBefore toleranceBefore: CMTime = .zero, toleranceAfter: CMTime = .zero) {
        guard isSeeking,
            let finalSeekTime = finalSeekTime else { return }

        cancelPendingSeeks()

        let info = SeekInfo(time: finalSeekTime, toleranceBefore: toleranceBefore, toleranceAfter: toleranceAfter)
        smoothlySeek(with: info)
    }

    func syncPlayerWithSeekTimeForPlayingIfNeeded() {
        guard isSeeking else { return }

        // Minimize the time to start playing by finishing seeking earlier with a higher
        // tolerance. This is mostly relevant for streamed iCloud items.
        seekToFinalTime(withToleranceBefore: .positiveInfinity, toleranceAfter: .positiveInfinity)
    }

    func syncPlayerWithSeekTimeForSteppingIfNeeded(isSteppingForward: Bool) {
        guard isSeeking else { return }

        // By default, stepping while seeking cancels seeking and steps from the current
        // player time. Instead, we want to step from the seek time. By replacing the current
        // seek with one with higher tolerance we (most likely) get the new seek to finish
        // before stepping begins. This is mostly relevant for streamed iCloud items.

        if isSteppingForward {
            seekToFinalTime(withToleranceBefore: .zero, toleranceAfter: .positiveInfinity)
        } else {
            seekToFinalTime(withToleranceBefore: .positiveInfinity, toleranceAfter: .zero)
        }
    }

    func syncPlayerWithSeekTimeForFinishScrubbingIfNeeded() {
        let twoSeeksRemaining = isSeeking && (nextSeek != nil)
        guard twoSeeksRemaining else { return }

        seekToFinalTime(withToleranceBefore: .zero, toleranceAfter: .zero)
    }

    func syncPlayerWithSeekTimeForImageExportIfNeeded() {
        guard isSeeking else { return }

        seekToFinalTime(withToleranceBefore: .positiveInfinity, toleranceAfter: .positiveInfinity)
    }
}
