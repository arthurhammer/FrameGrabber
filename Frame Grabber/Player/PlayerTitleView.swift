import UIKit

class PlayerTitleView: GradientView {

    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var dimensionsLabel: UILabel!
    @IBOutlet var frameRateLabel: UILabel!
    @IBOutlet var separatorLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        configureViews()
    }

    func setDetailLabels(for dimensions: String?, frameRate: String?, animated: Bool) {
        dimensionsLabel.text = dimensions
        frameRateLabel.text = frameRate

        let fadeDuration = 0.15
        dimensionsLabel.setHidden(dimensions == nil, animated: animated, duration: fadeDuration)
        frameRateLabel.setHidden(frameRate == nil, animated: animated, duration: fadeDuration)
        separatorLabel.setHidden((dimensions == nil) || (frameRate == nil), animated: animated, duration: fadeDuration)
    }

    private func configureViews() {
        colors = Style.Color.overlayTopGradient
        applyOverlayShadow()
    }
}
