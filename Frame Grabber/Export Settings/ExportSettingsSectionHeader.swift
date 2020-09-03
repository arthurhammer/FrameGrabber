import UIKit

class ExportSettingsSectionHeader: UITableViewHeaderFooterView {

    static var nib: UINib {
        UINib(nibName: String(describing: self), bundle: nil)
    }

    /// If true, aligns the title label by adding leading spacing.
    var isGroupedInset: Bool = true {
        didSet { updateViews() }
    }

    // When using custom headers, the default margin doesn't seem to be respected.
    let groupedInsetLeadingMargin: CGFloat = 8

    // Margin from the top of the title label to the previous section's footer (set in the view controller).
    let interSectionSpacing: CGFloat = 20
    let defaultVerticalMargins: CGFloat = 8

    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var leadingConstraint: NSLayoutConstraint!
    @IBOutlet var topConstraint: NSLayoutConstraint!

    override func awakeFromNib() {
        super.awakeFromNib()
        updateViews()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        updateViews()
    }

    private func updateViews() {
        // Slightly larger than normal.
        titleLabel.font = UIFont.preferredFont(forTextStyle: .headline, size: 18, weight: .semibold)

        leadingConstraint.constant = isGroupedInset ? groupedInsetLeadingMargin : 0
        topConstraint.priority = .defaultHigh
    }
}
