import UIKit

class VideoCell: UICollectionViewCell {

    @IBOutlet var imageView: UIImageView!
    @IBOutlet var selectionView: UIView!
    @IBOutlet var durationLabel: UILabel!
    @IBOutlet var favoritedImageView: UIImageView!

    var assetIdentifier: String!

    var thumbnailImage: UIImage! {
        didSet {
            imageView.image = thumbnailImage
        }
    }

    override var isSelected: Bool {
        didSet {
            selectionView.isHidden = !isSelected
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.5
        layer.shadowRadius = 10
        layer.shadowOffset = CGSize(width: 0, height: 0)

        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true

        selectionView.backgroundColor = UIColor.white.withAlphaComponent(0.5)
        selectionView.isHidden = true

        favoritedImageView.tintColor = .white
        favoritedImageView.isHidden = true
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        thumbnailImage = nil
        durationLabel.text = nil
        selectionView.isHidden = true
        favoritedImageView.isHidden = true
    }
}
