import UIKit

class PlayerControlsView: UIView {

    @IBOutlet var timeSlider: UISlider!
    @IBOutlet var playButton: UIButton!
    @IBOutlet var previousButton: RepeatingButton!
    @IBOutlet var nextButton: RepeatingButton!
    @IBOutlet var shareButton: UIButton!

    override func awakeFromNib() {
        super.awakeFromNib()
        configureViews()
    }

    func setControlsEnabled(_ enabled: Bool) {
        timeSlider.isEnabled = enabled
        shareButton.isEnabled = enabled
        playButton.isEnabled = enabled
        nextButton.isEnabled = enabled
        previousButton.isEnabled = enabled
    }

    private func configureViews() {
        backgroundColor = nil
        playButton.tintColor = Style.Color.secondaryTint
        previousButton.tintColor = Style.Color.secondaryTint
        nextButton.tintColor = Style.Color.secondaryTint

        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
        blurView.frame = bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        insertSubview(blurView, at: 0)
    }
}

// MARK: - Play Button

import AVKit

extension UIButton {
    func setTimeControlStatus(_ status: AVPlayer.TimeControlStatus) {
        setImage((status == .paused) ? UIImage(systemName: "play.fill") : UIImage(systemName: "pause.fill"), for: .normal)
    }
}
