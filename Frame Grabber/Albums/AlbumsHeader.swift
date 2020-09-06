import UIKit

class AlbumsHeader: UICollectionReusableView {
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var detailLabel: UILabel!
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    @IBOutlet var detailButton: UIButton!

    override func prepareForReuse() {
        super.prepareForReuse()
        
        detailButton.removeTarget(nil, action: nil, for: .touchUpInside)
    }
}
