import MapKit
import UIKit

class MetadataCell: UITableViewCell {
    
    @IBOutlet var titleLabel: UILabel?
    @IBOutlet var detailLabel: UILabel?
    
    var labelStack: UIStackView? {
        titleLabel?.superview as? UIStackView
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        updateViews()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if traitCollection.hasDifferentContentSize(comparedTo: previousTraitCollection) {
            updateViews()
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel?.text = nil
        detailLabel?.text = nil
        updateViews()
    }
    
    private func updateViews() {
        let isHuge = traitCollection.hasHugeContentSize
        labelStack?.axis = isHuge ? .vertical : .horizontal
        labelStack?.alignment = isHuge ? .leading : .center
    }
}
