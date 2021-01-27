import UIKit

class AlbumViewSettingsButton: UIButton {
    
    static let superviewMargin: CGFloat = 16

    override func awakeFromNib() {
        super.awakeFromNib()
        configureViews()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if previousTraitCollection?.hasDifferentColorAppearance(comparedTo: traitCollection) == true {
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
    
    /// Adds the receiver to the given view and sets up constraints.
    func add(to view: UIView) {
        let margin = AlbumViewSettingsButton.superviewMargin

        view.addSubview(self)
        translatesAutoresizingMaskIntoConstraints = false

        view.safeAreaLayoutGuide
            .leadingAnchor
            .constraint(lessThanOrEqualTo: leadingAnchor, constant: -margin)
            .isActive = true

        view.safeAreaLayoutGuide
            .trailingAnchor
            .constraint(equalTo: trailingAnchor, constant: margin)
            .isActive = true

        // 0 for notched phones, `margin` for non-notched phones.
        view.safeAreaLayoutGuide
            .bottomAnchor
            .constraint(greaterThanOrEqualTo: bottomAnchor, constant: 0)
            .isActive = true

        let bottomConstraint = view
            .bottomAnchor
            .constraint(equalTo: bottomAnchor, constant: margin)

        bottomConstraint.priority = .init(rawValue: 999)
        bottomConstraint.isActive = true
    }
}
