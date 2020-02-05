import UIKit

class EditorLoadingView: UIView {

    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var progressView: UIProgressView!

    override func awakeFromNib() {
        super.awakeFromNib()
        configureViews()
    }

    func setProgress(_ progress: Float?, animated: Bool) {
        progressView.setProgress(progress ?? 0, animated: animated)
        isHidden = progress == nil
    }

    private func configureViews() {
        applyOverlayShadow()
        progressView.trackTintColor = .white
        progressView.layer.cornerRadius = 4
        progressView.layer.masksToBounds = true
    }
}
