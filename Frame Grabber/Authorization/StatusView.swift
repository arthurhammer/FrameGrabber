import UIKit

struct StatusViewMessage {
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

    func displayMessage(_ message: StatusViewMessage?) {
        guard let message = message else {
            isHidden = true
            return
        }

        isHidden = false

        titleLabel.text = message.title
        messageLabel.text = message.message

        button.setTitle(message.action, for: .normal)
        button.isHidden = message.action == nil
    }

    private func configureViews() {
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .accent
        button.layer.cornerRadius = 12
    }
}
