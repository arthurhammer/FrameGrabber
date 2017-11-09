import UIKit

class VideoCellGradientView: UIView {

    override func awakeFromNib() {
        backgroundColor = .clear

        let gradient = CAGradientLayer()
        gradient.colors = [UIColor.black.withAlphaComponent(0).cgColor,
                           UIColor.black.withAlphaComponent(0.7).cgColor]
        gradient.frame = bounds
        layer.addSublayer(gradient)
    }
}
