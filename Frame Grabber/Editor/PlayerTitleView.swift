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

    func setDetailLabels(for dimensions: String?, frameRate: String?) {
        dimensionsLabel.text = dimensions
        frameRateLabel.text = frameRate

        dimensionsLabel.isHidden = dimensions == nil
        frameRateLabel.isHidden = frameRate == nil
        separatorLabel.isHidden =  dimensionsLabel.isHidden || frameRateLabel.isHidden
    }

    private func configureViews() {
        colors = Style.Color.overlayTopGradient
        applyOverlayShadow()
    }
}
