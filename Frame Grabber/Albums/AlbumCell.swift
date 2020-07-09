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
        imageView.contentMode = .center
    }

    private func configureViews() {
        imageView.layer.cornerRadius = 6
        imageView.layer.cornerCurve = .continuous
        selectedBackgroundView = UIView()
        selectedBackgroundView?.backgroundColor = Style.Color.cellSelection
    }
}
