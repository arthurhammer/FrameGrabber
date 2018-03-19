import UIKit

class PlayerOverlayView: UIView {

    @IBOutlet var titleView: PlayerTitleView!
    @IBOutlet var controlsView: PlayerControlsView!

    override func awakeFromNib() {
        super.awakeFromNib()
        configureViews()
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // Pass touches through overlay
        let hitView = super.hitTest(point, with: event)
        return (hitView == self) ? nil : hitView
    }

    private func configureViews() {
        titleView.colors = UIColor.playerOverlayNavigationGradient
        controlsView.colors = UIColor.playerOverlayControlsGradient

        let shadowViews: [UIView] = [titleView.titleLabel,
                                     controlsView.closeButton,
                                     controlsView.timeSlider,
                                     controlsView.timeLabel,
                                     controlsView.playButton,
                                     controlsView.shareButton,
                                     controlsView.previousButton,
                                     controlsView.nextButton]

        shadowViews.forEach {
            $0.applyDefaultOverlayShadow()
        }
    }
}

private extension UIView {
    func applyDefaultOverlayShadow() {
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.5
        layer.shadowRadius = 4
        layer.shadowOffset = CGSize(width: 0, height: 2)
    }
}
