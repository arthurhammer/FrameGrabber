import UIKit

class VideoDetailSectionHeader: UITableViewHeaderFooterView {

    static var nib: UINib {
        UINib(nibName: String(describing: self), bundle: nil)
    }

    var isGroupedInset: Bool = true {
        didSet { updateViews() }
    }

    // When using custom headers, the default margin doesn't seem to be respected.
    let groupedInsetCustomHeaderMargin: CGFloat = 8

    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var leadingConstraint: NSLayoutConstraint!

    override func awakeFromNib() {
        super.awakeFromNib()
        updateViews()
    }

    private func updateViews() {
        // Slightly larger than normal
        titleLabel.font = UIFont.preferredFont(forTextStyle: .headline, size: 18, weight: .semibold)
        leadingConstraint.constant = isGroupedInset ? groupedInsetCustomHeaderMargin : 0
    }
}
