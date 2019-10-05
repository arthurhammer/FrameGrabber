import UIKit

class FrameCell: UICollectionViewCell {

    @IBOutlet var imageView: UIImageView!
    @IBOutlet var deleteButton: UIButton!

    let selectionCornerRadius: CGFloat = 8
    var selectionBorderWidth: CGFloat = 0 {
        didSet { updateViews() }
    }

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
        imageView.image = nil
    }

    private func configureViews() {
        imageView.backgroundColor = Style.Color.cellSelection

        let selectionView = UIView()
        selectionView.backgroundColor = .white
        selectionView.layer.cornerRadius = selectionCornerRadius
        selectionView.clipsToBounds = false
        selectedBackgroundView = selectionView

        deleteButton.tintColor = .white
        deleteButton.backgroundColor = UIColor.black.withAlphaComponent(0.3)

        updateViews()
    }

    private func updateViews() {
        let highlight = isSelected || isHighlighted
        // UIKit calls `isSelected`/`isHighlighted` setters with animation blocks. Use
        // `alpha` instead of `isHidden` to animate alongside the default animation.
        self.deleteButton.alpha = highlight ? 1 : 0
        let innerRadius = selectionCornerRadius - selectionBorderWidth
        imageView.superview?.layer.cornerRadius = highlight ? innerRadius : 0
    }
}
