import UIKit
import Combine

class VideoCell: UICollectionViewCell {
    
    var identifier: String?
    var imageRequest: Cancellable?

    @IBOutlet var imageView: UIImageView!
    @IBOutlet var durationLabel: UILabel!
    @IBOutlet var favoritedImageView: UIImageView!
    @IBOutlet var livePhotoImageView: UIImageView!
    @IBOutlet var gradientView: GradientView!

    @IBOutlet var imageContainer: UIView!
    @IBOutlet var imageContainerWidthConstraint: NSLayoutConstraint!
    @IBOutlet var imageContainerHeightConstraint: NSLayoutConstraint!
    
    static let fadeOverlaysAnimationDuration: TimeInterval = 0.2
    static let contentModeAnimationDuration: TimeInterval = 0.15

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
        livePhotoImageView.isHidden = true
    }

    private func configureViews() {
        gradientView.colors = UIColor.videoCellGradient
        imageView.contentMode = .scaleAspectFill
        prepareForReuse()
    }

    func fadeInOverlays() {
        gradientView.alpha = 0

        UIView.animate(withDuration: VideoCell.fadeOverlaysAnimationDuration) {
            self.gradientView.alpha = 1
        }
    }

    func setGridContentMode(_ mode: AlbumGridContentMode, forAspectRatio aspectRatio: CGSize, animated: Bool) {
        let setMode = {
            let targetSize = mode.thumbnailSize(for: aspectRatio, in: self.bounds.size)
            self.imageContainerWidthConstraint.constant = targetSize.width
            self.imageContainerHeightConstraint.constant = targetSize.height
            self.imageContainer.layoutIfNeeded()
        }

        if animated {
            UIView.animate(
                withDuration: VideoCell.contentModeAnimationDuration,
                delay: 0,
                options: [.beginFromCurrentState, .curveEaseInOut],
                animations: setMode
            )
        } else {
            setMode()
        }
    }
}
