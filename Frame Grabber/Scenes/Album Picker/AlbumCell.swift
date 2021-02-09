import UIKit
import Combine

class AlbumCell: UICollectionViewCell {

    var identifier: String?
    var imageRequest: Cancellable?

    @IBOutlet var imageView: UIImageView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var detailLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        configureViews()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        identifier = nil
        imageRequest = nil
        titleLabel.text = nil
        detailLabel.text = nil
        imageView.image = nil
    }

    private func configureViews() {
        imageView.layer.cornerRadius = 12
        imageView.layer.cornerCurve = .continuous

        selectedBackgroundView = UIView()
        selectedBackgroundView?.backgroundColor = .cellSelection
        selectedBackgroundView?.layer.cornerRadius = 12
        selectedBackgroundView?.layer.cornerCurve = .continuous
        
        // Allow the selection to spill over.
        clipsToBounds = false
        let selectionFrame = bounds.inset(by: UIEdgeInsets(top: 0, left: -10, bottom: 0, right: -10))
        selectedBackgroundView?.frame = selectionFrame
    }
}
