import UIKit
import Photos

class VideoCell: UICollectionViewCell {

    var identifier: String?
    var imageRequest: PHImageManager.Request?

    @IBOutlet var imageView: UIImageView!
    @IBOutlet var durationLabel: UILabel!
    @IBOutlet var favoritedImageView: UIImageView!
    @IBOutlet var highlightView: UIView!
    @IBOutlet var gradientView: GradientView!

    override var isHighlighted: Bool {
        didSet { updateViews() }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        configureViews()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        isHidden = false
        identifier = nil
        imageRequest = nil
        imageView.image = nil
        durationLabel.text = nil
        favoritedImageView.isHidden = true
        updateViews()
    }

    private func configureViews() {
        highlightView.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        gradientView.colors = Style.Color.videoCellGradient
        favoritedImageView.isHidden = true
        updateViews()
    }

    private func updateViews() {
        highlightView.isHidden = !isHighlighted
    }
}
