import UIKit

class AlbumListHeader: UICollectionReusableView {
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var detailLabel: UILabel!
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        configureViews()
    }
    
    private func configureViews() {
        titleLabel.font = .preferredFont(forTextStyle: .headline, size: 22, weight: .semibold)
    }
}
