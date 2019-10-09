import UIKit

class StatusView: UIView {

    struct Message {
        let title: String
        let message: String
        let action: String?
    }

    var message: Message? {
        didSet { updateViews() }
    }

    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var messageLabel: UILabel!
    @IBOutlet var button: UIButton!

    override func awakeFromNib() {
        super.awakeFromNib()
        configureViews()
    }

    private func configureViews() {
        button.tintColor = .white
        button.backgroundColor = Style.Color.mainTint
        button.layer.cornerRadius = Style.Size.buttonCornerRadius

        titleLabel.font = UIFont.preferredFont(forTextStyle: .title1, weight: .semibold)
    }

    private func updateViews() {
        isHidden = message == nil

        titleLabel.text = message?.title
        messageLabel.text = message?.message

        button.setTitle(message?.action, for: .normal)
        button.isHidden = message?.action == nil
    }
}
