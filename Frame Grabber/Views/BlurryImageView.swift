import UIKit

class BlurryImageView: UIView {

    var imageView: UIImageView!
    var visualEffectView: UIVisualEffectView!

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureViews()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configureViews()
    }

    private func configureViews() {
        imageView = UIImageView()
        imageView.frame = bounds
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        imageView.contentMode = .scaleAspectFill
        addSubview(imageView)

        visualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        visualEffectView.frame = bounds
        visualEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(visualEffectView)
    }
}
