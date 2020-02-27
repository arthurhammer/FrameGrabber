import UIKit

class VideoDetailSectionHeader: UITableViewHeaderFooterView {

    static var nib: UINib {
        UINib(nibName: String(describing: self), bundle: nil)
    }
    
    var isGroupedInset: Bool = true {
        didSet { updateViews() }
    }

    var hasPreviousFooter: Bool = false {
        didSet { updateViews() }
    }

    // When using custom headers, the default margin doesn't seem to be respected.
    let groupedInsetCustomHeaderMargin: CGFloat = 8
    let additionalTopSpacing: CGFloat = 20 

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
        // Slightly larger than normal
        titleLabel.font = UIFont.preferredFont(forTextStyle: .headline, size: 18, weight: .semibold)
        leadingConstraint.constant = isGroupedInset ? groupedInsetCustomHeaderMargin : 0
        topConstraint.constant = hasPreviousFooter ? additionalTopSpacing : 8
    }
}
