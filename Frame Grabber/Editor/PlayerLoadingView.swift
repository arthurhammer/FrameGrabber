import UIKit

class PlayerLoadingView: UIView {

    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var progressView: UIProgressView!
    @IBOutlet var imageView: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        configureViews()
    }

    func setProgress(_ progress: Float?, animated: Bool) {
        let hide = progress == nil
        progressView.setProgress(progress ?? 0, animated: animated)
        progressView.isHidden = hide
        titleLabel.isHidden = hide
    }

    private func configureViews() {
        titleLabel.applyOverlayShadow()
        progressView.applyOverlayShadow()
        progressView.trackTintColor = .white
        progressView.layer.cornerRadius = 4
        progressView.layer.masksToBounds = true
    }
}
