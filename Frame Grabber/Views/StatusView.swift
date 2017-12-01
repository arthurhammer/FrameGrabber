import UIKit

struct StatusMessage {
    let title: String
    let message: String
    let action: String?
}

class StatusView: UIView {

    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var messageLabel: UILabel!
    @IBOutlet var button: UIButton!

    override func awakeFromNib() {
        super.awakeFromNib()
        configureViews()
    }

    func displayMessage(_ message: StatusMessage?) {
        guard let message = message else {
            isHidden = true
            return
        }

        titleLabel.text = message.title
        messageLabel.text = message.message
        button.setTitle(message.action, for: .normal)
        button.isHidden = message.action == nil
        isHidden = false
    }

    private func configureViews() {
        titleLabel.textColor = .white
        messageLabel.textColor = .white

        button.setTitleColor(.mainBackground, for: .normal)
        button.backgroundColor = .accent
        button.layer.cornerRadius = defaultCornerRadius
    }
}
