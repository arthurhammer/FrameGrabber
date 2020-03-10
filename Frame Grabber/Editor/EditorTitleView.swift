import UIKit
import CoreMedia

class EditorTitleView: UIView {

    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var timeLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        configureViews()
    }

    func setEnabled(_ enabled: Bool) {
        titleLabel.isEnabled = enabled
        timeLabel.isEnabled = enabled
    }

    func setFormattedTime(_ formattedTime: String?, animated: Bool) {
        if animated {
            UIView.animate(withDuration: 0.15, delay: 0, options: .beginFromCurrentState, animations: {
                self.timeLabel.text = formattedTime
                self.timeLabel.superview?.layoutIfNeeded()
            }, completion: nil)
        } else {
            timeLabel.text = formattedTime
        }
    }

    private func configureViews() {
        timeLabel.font = .monospacedDigitSystemFont(ofSize: 12, weight: .regular)
    }
}
