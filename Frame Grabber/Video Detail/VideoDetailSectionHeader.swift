import UIKit

class VideoDetailSectionHeader: UITableViewHeaderFooterView {

    static var nib: UINib {
        UINib(nibName: String(describing: self), bundle: nil)
    }

    var isGroupedInset: Bool = true {
        didSet { updateViews() }
    }

    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var leadingConstraint: NSLayoutConstraint!

    override func awakeFromNib() {
        super.awakeFromNib()
        updateViews()
    }

    private func updateViews() {
        // Slightly larger than normal
        titleLabel.font = UIFont.preferredFont(forTextStyle: .headline, size: 18, weight: .semibold)

        if #available(iOS 13, *), isGroupedInset {
            leadingConstraint.constant = isGroupedInset ? 8 : 0
        } else {
            leadingConstraint.constant = 0
        }
    }
}
