import UIKit

class GradientView: UIView {

    override static var layerClass: AnyClass {
        CAGradientLayer.self
    }

    var gradientLayer: CAGradientLayer {
        layer as! CAGradientLayer
    }

    var colors: [UIColor] {
        get {
            let colors = (gradientLayer.colors as? [CGColor]) ?? []
            return colors.map(UIColor.init)
        }
        set { gradientLayer.colors = newValue.map { $0.cgColor } }
    }
}
