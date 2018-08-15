import UIKit

class PlayerOverlayView: UIView {

    @IBOutlet var titleView: PlayerTitleView!
    @IBOutlet var controlsView: PlayerControlsView!

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // Pass touches through if not in a subview (title, controls).
        let hitView = super.hitTest(point, with: event)
        return (hitView != self) ? hitView : nil
    }
}
