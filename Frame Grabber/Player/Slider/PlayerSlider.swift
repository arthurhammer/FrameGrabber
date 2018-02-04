import UIKit
import AVKit

class PlayerSlider: ScrubbingSlider {

    override func awakeFromNib() {
        super.awakeFromNib()
        configureViews()
    }

    private func configureViews() {
        let thumbSize = CGSize(width: 4, height: 26)
        let thumbCornerRadius = thumbSize.width / 2
        let trackHeight: CGFloat = 8
        let trackCornerRadius = trackHeight / 2

        setThumbSize(thumbSize, cornerRadius: thumbCornerRadius, color: .timeSliderThumbTint, for: .normal)
        setMinimumTrackHeight(trackHeight, cornerRadius: trackCornerRadius, color: .timeSliderMinimumTrackTint, for: .normal)
        setMaximumTrackHeight(trackHeight, cornerRadius: trackCornerRadius, color: .timeSliderMaximumTrackTint, for: .normal)
    }
}
