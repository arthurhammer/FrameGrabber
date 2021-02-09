import UIKit

class LibraryFilterButton: UIButton {
    
    static let superviewMargin: CGFloat = 16

    override func awakeFromNib() {
        super.awakeFromNib()
        configureViews()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateViews()
        }
    }

    private func configureViews() {
        clipsToBounds = false
        layer.cornerRadius = Style.buttonCornerRadius
        layer.cornerCurve = .continuous

        titleLabel?.font = .preferredFont(forTextStyle: .subheadline, weight: .semibold)
        titleLabel?.adjustsFontForContentSizeCategory = true

        setImage(UIImage(systemName: "line.horizontal.3.decrease.circle"), for: .normal)
        backgroundColor = UIColor.systemBackground.withAlphaComponent(0.95)
        applyToolbarShadow()
        
        updateViews()
    }
    
    private func updateViews() {
        layer.borderWidth = 1
        layer.borderColor = UIColor.systemGray6.cgColor
    }
}
