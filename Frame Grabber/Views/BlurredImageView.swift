import UIKit

class BlurredImageView: UIView {

    let imageView = UIImageView()
    let visualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .systemThickMaterial))

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureViews()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configureViews()
    }

    private func configureViews() {
        imageView.frame = bounds
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true

        visualEffectView.frame = bounds
        visualEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        insertSubview(imageView, at: 0)
        insertSubview(visualEffectView, at: 1)
    }
}
