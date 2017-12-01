import UIKit

class VideoCell: UICollectionViewCell {

    @IBOutlet var imageView: UIImageView!
    @IBOutlet var selectionView: UIView!
    @IBOutlet var durationLabel: UILabel!
    @IBOutlet var favoritedImageView: UIImageView!

    var assetIdentifier: String?
    var imageRequest: ImageRequest?

    override var isSelected: Bool {
        didSet { updateViews() }
    }

    override var isHighlighted: Bool {
        didSet { updateViews() }
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        backgroundColor = .darkGray  // When thumbnail missing
        selectionView.backgroundColor = UIColor.white.withAlphaComponent(0.6)

        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        favoritedImageView.tintColor = .white
        favoritedImageView.isHidden = true

        updateViews()
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        imageView.image = nil
        imageRequest = nil
        durationLabel.text = nil
        selectionView.isHidden = true
        favoritedImageView.isHidden = true
    }

    private func updateViews() {
        selectionView.isHidden = !isSelected && !isHighlighted
    }
}
