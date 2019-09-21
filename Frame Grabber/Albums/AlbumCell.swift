import UIKit

class AlbumCell: UICollectionViewCell {

    var identifier: String?
    var imageRequest: ImageRequest?

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
        imageView.image = nil
        titleLabel.text = nil
        detailLabel.text = nil
    }

    private func configureViews() {
        imageView.layer.cornerRadius = 4
        selectedBackgroundView = UIView()
        selectedBackgroundView?.backgroundColor = Style.Color.cellSelection
    }
}
