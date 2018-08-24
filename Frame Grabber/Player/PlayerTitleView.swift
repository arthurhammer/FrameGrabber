import UIKit

class PlayerTitleView: GradientView {

    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var detailLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        configureViews()
    }

    private func configureViews() {
        colors = Style.Color.overlayTopGradient
        applyOverlayShadow()
    }
}
