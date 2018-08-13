import UIKit

class PlayerLoadingView: UIView {
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var progressView: UIProgressView!
    @IBOutlet var previewImageView: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        configureViews()
    }

    private func configureViews() {
        progressView.progressTintColor = .accent
        progressView.trackTintColor = .white
        progressView.layer.cornerRadius = 4
        progressView.layer.masksToBounds = true
    }
}
