import UIKit

class VideoCell: UICollectionViewCell {

    var identifier: String?
    var imageRequest: ImageRequest?

    @IBOutlet var imageView: UIImageView!
    @IBOutlet var durationLabel: UILabel!
    @IBOutlet var favoritedImageView: UIImageView!
    @IBOutlet var selectionView: UIView!
    @IBOutlet var gradientView: GradientView!

    override var isSelected: Bool {
        didSet { updateViews() }
    }

    override var isHighlighted: Bool {
        didSet { updateViews() }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        configureViews()
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        identifier = nil
        imageRequest = nil
        imageView.image = nil
        durationLabel.text = nil
        selectionView.isHidden = true
        favoritedImageView.isHidden = true
    }

    private func configureViews() {
        backgroundColor = .missingThumbnail
        selectionView.backgroundColor = UIColor.white.withAlphaComponent(0.6)
        gradientView.colors = UIColor.videoCellGradient

        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        favoritedImageView.tintColor = .white
        favoritedImageView.isHidden = true

        updateViews()
    }

    private func updateViews() {
        selectionView.isHidden = !isSelected && !isHighlighted
    }
}
