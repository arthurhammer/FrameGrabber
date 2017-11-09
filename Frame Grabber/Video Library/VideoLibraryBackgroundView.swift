import UIKit

class VideoLibraryBackgroundView: UIView {

    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var messageLabel: UILabel!

    override func awakeFromNib() {
        backgroundColor = .clear
        titleLabel.textColor = .videoLibrarySecondaryLabelColor
        messageLabel.textColor = .videoLibrarySecondaryLabelColor
    }
}
