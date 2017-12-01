import UIKit
import AVKit

// TODO: !!! reference cycle
// TODO: revamp authorization design for navigation bar (show/hide, title ...?)

// Repeating button vs bumpy button
// for now keep like this but later extract into standalone player view controller

class RepeatingButton: UIButton {

}


class ScrubberSeeker {

    private(set) weak var player: AVPlayer?

    // strong weak!?
    init(slider: UISlider, player: AVPlayer) {
        // TODO: ready to play? ....
        self.player = player
        slider.addTarget(self, action: #selector(scrub), for: .valueChanged)
        slider.addTarget(self, action: #selector(scrudDidEnd), for: [.touchUpInside, .touchUpOutside])
    }

    @objc private func scrub(_ slider: UISlider) {

    }

    @objc private func scrudDidEnd(_ slider: UISlider) {

    }
}

// TODO
private extension UISlider {
    /// The current value interpreted as a `CMTime`.
    var time: CMTime {
        return CMTime(seconds: Double(value))
    }
}

protocol AVPlayerViewControllerDelegate {
    func done()
}

class PlayerViewController: UIViewController {

    var video: Video! {
        didSet {
            guard video != nil else { fatalError("Video is required") }
            loadPlayerItem()
        }
    }

    private(set) var player: AVPlayer? {
        didSet {
            guard let player = player else {
                observer = nil
                playerView.player = nil
                // TODO: reset/disable controls
                return
            }

            // TODO
            if playerView.player != player {
                playerView.player = player
            }

            observer = PlayerObserver(player: player)
            observer?.delegate = self
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureViews()
    }

    @IBAction func done() {
        dismiss(animated: true)
    }

    @IBAction func playOrPause() {
//        playbackControlsView.playButton.bump(by: 1.1)
        millis = false
        player?.playOrPause()
    }

    @IBAction func stepBackward() {
        millis = true
//        playbackControlsView.timeLabel.highlightedTextColor = .white
//        playbackControlsView.timeLabel.isHighlighted = true
        player?.step(by: -1)

//        playbackControlsView.timeLabel.bump(by: 0.9, withDuration: 0.1)
    }

    var millis = false

    @IBAction func stepForward() {
        player?.step(by: 1)
        playbackControlsView.timeLabel.bump(by: 1.1, withDuration: 0.1)
    }

    // TODO: extract somehow. really ugly
    // TODO: clean up/finish before moving on
    // TODO: clean/finish before moving on!!
    // TODO: comments. why, will forget in months -> explain smooth scrubbing with callbacks

    @IBAction func scrub(_ slider: UISlider) {
        guard let player = player else { return }
        millis = true

        // Scrubbing started
        if !isScrubbing {
            isScrubbing = true
            wasPlaying = player.isPlaying
            player.pause()
        }

        // Scrub time changed
        let needsToSeek = goalSeekTime != slider.time
        goalSeekTime = slider.time

        // Don't interrupt a seek in progress.
        // If necessary, another seek is started when the current one finishes (see below).
        if needsToSeek && !isSeeking {
            seekToGoalTime()
        }
    }

    @IBAction func doubleTap() {
        // TEST (REMOVE)
        // TODO: dont do if in controls view
    }

    @IBAction func finishScrubbing(_ slider: UISlider) {
        isScrubbing = false
        resumePlayingAfterScrubbingIfNecessary()
    }

    private func seekToGoalTime() {
        isSeeking = true
        player?.seek(to: goalSeekTime/*controlsView.scrubbingSlider.time*/, toleranceBefore: .zero, toleranceAfter: .zero, completionHandler: finishSeeking)
    }

    // rename
    private func finishSeeking(finished: Bool) {
        isSeeking = false
        let needsToSeek = goalSeekTime/*controlsView.scrubbingSlider.time*/ != player?.currentTime()

        // A seek finished but the scrub value changed during the seek. Resume.
        if needsToSeek {
            seekToGoalTime()
            return
        }

        resumePlayingAfterScrubbingIfNecessary()
    }

    private func resumePlayingAfterScrubbingIfNecessary() {
        // Seeking might still be in progress while scrubbing is finished and vice versa.
        // (Example: User's finger becomes stationary during a scrub. The seek will finish
        //  but the player should not resume before the finger is released.)
        if wasPlaying && !playbackControlsView.timeSlider.isTracking && !isSeeking {
            player?.play()
        }
    }
//
//    private var backgroundView: PlayerBackgroundView {
//        return view as! PlayerBackgroundView
//    }

    @IBOutlet private var playerView: ZoomingPlayerView!
    @IBOutlet private var playbackControlsView: PlaybackControlsView!
    @IBOutlet private var doneButton: UIButton!
    private var observer: PlayerObserver?

    private var goalSeekTime: CMTime = .zero // nil/optional?
    private var wasPlaying = false
    /// Whether the user is interacting with the slider.
    private var isScrubbing = false
    /// Whether the player is performing a seek. Scrubbing != seeking as seeks can finish while the finger is stationary on the slider. Also, scrubs can finish while a seek is still in progress. We want to resume playing only if both are finished.
    private var isSeeking = false

    private lazy var timeFormatter = VideoTimeFormatter()

    private var blurry = true
}

// MARK: - ZoomingPlayerViewDelegate

extension PlayerViewController: ZoomingPlayerViewDelegate {

    // CLEAN this up
    func playerViewDidZoom(_ playerView: ZoomingPlayerView) {
        // Extract into some update method
        let rect = playerView.zoomedVideoRect
        // TODO: conversion which coordinate space
        // TODO: only blur if not alreay -> otherwise constant unblur blur!!!!! UGLY

        let otherRect = playbackControlsView.timeSlider.convert(playbackControlsView.timeSlider.bounds, to: playerView)

        
        // still buggy doesnt always work + accessibility = judt black?
        if rect.intersects(otherRect) {
            if !blurry { return }
            blurry = false

            playbackControlsView.blur(with: .dark)

            // start from initial state maybe!?
            // animation awesome tooo!! maybe subclass or sth!? make this nice
            UIView.animate(withDuration: 0.2, delay: 0, options:.beginFromCurrentState, animations: ({
                self.view.subviews.first?.backgroundColor = .mainBackground  // yes! this is good! way better effect
            }), completion: nil)
//            UIView.animate(withDuration: 1){
//                self.view.subviews.first?.backgroundColor = .red  // yes! this is good! way better effect
//            }
//            view.backgroundColor = .mainBackground
//            view.removeBlur()  // TEST
        } else {
            if blurry { return }
            blurry = true
//            view.blur(with: .dark)
            //UIView.animate(withDuration: 0.4){
                self.view.subviews.first?.backgroundColor = nil  // yes! this is good! way better effect
            //}
            playbackControlsView.removeBlur()
        }
    }
}

// MARK: - PlayerObserverDelegate

extension PlayerViewController: PlayerObserverDelegate {

    // States:
    //   - player is nil because item not loaded
    //   - item is nil for some reason
    //   - item or player failed.
    //   - item/player are not ready to play
    //   - player is waiting to play at specified rate
    //   - item/player are ready to play
    //      - can step/cannot step

    // native player on waiting state: disables play button and REPLACES current time only with indicator

    // SEEK! + no item, can seek etc. all these states
    // no item, failed, buffering, not ready (disable slider, disable other stuff)

    func didUpdateTimeControlStatus(_ status: AVPlayerTimeControlStatus, of player: AVPlayer) {
        millis = status == .paused  // Remove this!!
        playbackControlsView.playButton.setImage(status.playButtonImage, for: .normal)  // todo: waiting state -> should disable or REPLACE button when
        updateViews()
    }

    func didUpdateReasonForWaitingToPlay(_ reason: AVPlayer.WaitingReason?, of player: AVPlayer) {
        let showActivity = (reason == .noItemToPlay) || (reason == .toMinimizeStalls)
        playbackControlsView.setActivityIndicatorEnabled(showActivity)
        updateViews()
    }

    func didUpdateStatus(_ status: AVPlayerStatus, of player: AVPlayer) {
        // TODO
        updateViews()
    }

    func didUpdateCurrentItem(_ item: AVPlayerItem?, of player: AVPlayer) {
        // disable controls
        updateViews()
    }

    func didUpdateStatus(_ status: AVPlayerItemStatus, ofCurrentPlayerItem item: AVPlayerItem) {
        // error handling
        // disable controls if not ready
        print(status)

        if case .readyToPlay = status {
            // check if cmtime valid etc (see cmtime)
            // todo: step controls etc!!
            playbackControlsView.timeSlider.maximumValue = Float(item.duration.seconds)  // ?? seconds correct?!
            //controlsView.videoDimensionsLabel.text = VideoDimensionFormatter().string(from: item.presentationSize)  // todo: this is video dimensions label + initial/empty text
        }

        updateViews()
    }

    func didPeriodicUpdate(at time: CMTime, for player: AVPlayer) {
        playbackControlsView.timeLabel.text = timeFormatter.string(fromCurrentTime: time, includeMilliseconds: millis)
        playbackControlsView.timeSlider.setValue(Float(time.seconds), animated: true)
    }
}

private extension PlayerViewController {

    func configureViews() {
        updateViews()
        view.blur(with: .dark)
        // extract
        doneButton.tintColor = .playbackControlsTint
        doneButton.layer.cornerRadius = defaultCornerRadius
        doneButton.layer.masksToBounds = true
        doneButton.blur(with: .dark)
        doneButton.bringSubview(toFront: doneButton.imageView!)  // TODO

        playerView.delegate = self



        // TODO: close button same color as others; buttonaligns with play button (isnt currently!!)


        // player/item can be ready/failed before view is loaded. need to set views only on CURRENT state of player not some imagined initial state.
    }

    func updateViews() {
        let ready = (player?.status == .readyToPlay) && (player?.currentItem?.status == .readyToPlay)
        let failedOrNil = (player == nil) || (player?.currentItem == nil) || (player?.status == .failed) || (player?.currentItem?.status == .failed)
        // todo: reset labels: time + dimensions
        playbackControlsView.setPlayerControlsEnabled(ready)
        playbackControlsView.setActivityIndicatorEnabled(failedOrNil)
        updateCurrentTime()

        if ready {
//            controlsView.timeScrubber.maximumValue = Float(item.duration.seconds)
//            controlsView.videoDimensionsLabel.text = VideoDimensionFormatter().string(from: item.presentationSize)  // todo: this is video dimensions label + initial/empty text
        }

        guard let player = player, let item = player.currentItem else {
            // disable
            return
        }

        if ready {
            playbackControlsView.dimensionsLabel.text = VideoDimensionFormatter().string(from: item.presentationSize)
        }

        
    }

    func updateCurrentTime() {
        
    }

    func loadPlayerItem() {
        video.loadPlayerItem { video, status in
            // TODO: Check if view is loaded! Otherwise fails (UIAlertController, statusController, playerViewController)

            switch status {
            case .notLoaded, .loading:
                break
            case .failed(let error):
                // TODO: status controller
                self.handleErrorWithMessage("Video failed", error: error)
                break
            case .loaded(let playerItem):
                self.configurePlayer(for: playerItem)
            }
        }
    }

    func configurePlayer(for item: AVPlayerItem) {
        player = LoopingPlayer(templateItem: item)
//        playerObserver = PlayerObserver(player: player)
//        playerObserver?.delegate = self
//        playerViewController.player = player
    }

    func handleErrorWithMessage(_ message: String?, error: Error? = nil) {
        let alert = UIAlertController(title: .defaultAlertTitle,
                                      message: message ?? .defaultAlertMessage,
                                      preferredStyle: UIAlertControllerStyle.alert)

        let ok = UIAlertAction(title: .okAlertAction, style: .default, handler: nil)

        alert.addAction(ok)

        present(alert, animated: true, completion: nil)
    }
}

private extension AVPlayerTimeControlStatus {
    var playButtonImage: UIImage {
        switch self {
        case .playing, .waitingToPlayAtSpecifiedRate:
            return UIImage(named: "pause")!
        case .paused:
            return UIImage(named: "play")!
        }
    }
}
