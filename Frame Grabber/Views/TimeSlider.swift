import UIKit

class TimeSlider: UISlider {

    @IBInspectable var trackHeight: CGFloat = 8 {
        didSet { setNeedsDisplay() }
    }

    override func trackRect(forBounds bounds: CGRect) -> CGRect {
        let defaultBounds = super.trackRect(forBounds: bounds)

        return CGRect(x: defaultBounds.origin.x,
                      y: defaultBounds.origin.y + defaultBounds.size.height/2 - trackHeight/2,
                      width: defaultBounds.size.width,
                      height: trackHeight)
    }
}
