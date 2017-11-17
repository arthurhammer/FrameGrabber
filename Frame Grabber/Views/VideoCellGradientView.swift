import UIKit

class VideoCellGradientView: UIView {

    private lazy var gradient: CAGradientLayer = {
        let gradient = CAGradientLayer()
        gradient.colors = [UIColor.black.withAlphaComponent(0).cgColor,
                           UIColor.black.withAlphaComponent(0.7).cgColor]
        layer.addSublayer(gradient)
        return gradient
    }()

    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = .clear
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradient.frame = bounds
    }
}
