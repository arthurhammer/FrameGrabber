import Utility
import UIKit

class AlbumListHeader: UICollectionReusableView {
    
    @IBOutlet private(set) var titleLabel: UILabel!
    @IBOutlet private(set) var detailLabel: UILabel!
    @IBOutlet private(set) var activityIndicator: UIActivityIndicatorView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        configureViews()
    }
    
    private func configureViews() {
        titleLabel.font = .preferredFont(forTextStyle: .headline, weight: .semibold, size: 22)
    }
}
