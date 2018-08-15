import UIKit

class PlayerTitleView: GradientView {

    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var detailTitleLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        configureViews()
    }

    private func configureViews() {
        colors = UIColor.playerOverlayNavigationGradient
        applyDefaultOverlayShadow()
    }
}
