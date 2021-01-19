import CoreMedia
import UIKit

class ThumbnailSliderTrack: UIView {

    var thumbnailViews: [ThumbnailImageView] {
        (thumbnailStack.arrangedSubviews as? [ThumbnailImageView]) ?? []
    }

    var thumbnailSize: CGSize {
        thumbnailViews.first?.bounds.size ?? .zero
    }

    var isEnabled: Bool = true {
        didSet { updateViews() }
    }

    var disabledTintColor = UIColor.systemBackground.withAlphaComponent(0.4) {
        didSet { disabledTintView.backgroundColor = disabledTintColor }
    }
    
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if previousTraitCollection?.hasDifferentColorAppearance(comparedTo: traitCollection) == true {
            updateViews()
        }
    }
    
    public override func tintColorDidChange() {
        super.tintColorDidChange()
        updateViews()
    }

    private lazy var thumbnailStack: UIStackView = {
        let view = UIStackView(frame: bounds)
        view.autoresizingMask = .flexibleHeight
        view.axis = .horizontal
        view.alignment = .fill
        view.distribution = .fillEqually
        view.spacing = 0
        return view
    }()
    
    /// Exact placement is managed by the superview.
    private(set) lazy var progressTintView: UIView = {
        let frame = CGRect(x: 0, y: 0, width: 0, height: bounds.height)
        let view = UIView(frame: frame)
        view.autoresizingMask = .flexibleHeight
        return view
    }()

    private lazy var disabledTintView: UIView = {
        let view = UIView(frame: bounds)
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.backgroundColor = disabledTintColor
        return view
    }()
    
    private let disabledBorderColor = UIColor.systemGray4

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureViews()
    }

    func clearThumbnails() {
        thumbnailStack.arrangedSubviews.forEach(thumbnailStack.removeArrangedSubview)
        thumbnailStack.subviews.forEach { $0.removeFromSuperview() }
    }

    /// Creates thumbnail views in size and amount fitting the given parameters.
    ///
    /// The thumbnail views currently in the track are removed.
    ///
    /// - Parameters:
    ///   - aspectRatio: The preferred thumbnail aspect ratio. The aspect ratio is scaled to fit the track's height.
    ///   - minimumWidth: The minimum width of thumbnails. If given, the scaled aspect ratio is stretched to fit this
    ///     value, thereby losing its original aspect ratio.
    ///   - maximumWidth: The maximum width of thumbnails. If given, the scaled aspect ratio is stretched to fit this
    ///     value, thereby losing its original aspect ratio.
    func makeThumbnails(
        withAspectRatio aspectRatio: CGSize,
        minimumWidth: CGFloat = 1,
        maximumWidth: CGFloat = .greatestFiniteMagnitude
    ) {
        clearThumbnails()

        guard var thumbnailSize = aspectRatio.aspectFitting(height: bounds.height),
            thumbnailSize.width != 0 else { return }

        thumbnailSize.width = thumbnailSize.width.clamped(to: minimumWidth, and: maximumWidth)
        
        let amount = Int(ceil(bounds.width / thumbnailSize.width))

        (0..<amount).forEach { _ in
            let imageView = ThumbnailImageView()
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            thumbnailStack.addArrangedSubview(imageView)
        }

        thumbnailStack.frame.size.width = CGFloat(amount) * thumbnailSize.width
        thumbnailStack.frame.origin = .zero
        thumbnailStack.layoutIfNeeded()

        updateViews()
    }

    func thumbnailOffsets(in view: UIView?) -> [CGFloat] {
        thumbnailViews.map {
            thumbnailStack.convert($0.frame.origin, to: view).x
        }
    }

    private func configureViews() {
        isUserInteractionEnabled = false
        clipsToBounds = true
        
        addSubview(thumbnailStack)
        addSubview(progressTintView)
        addSubview(disabledTintView)
        
        updateViews()
    }

    private func updateViews() {
        disabledTintView.isHidden = isEnabled
        progressTintView.isHidden = !isEnabled
        
        progressTintView.backgroundColor = tintColor.withAlphaComponent(0.5)
        layer.borderColor = isEnabled ? tintColor.cgColor : disabledBorderColor.cgColor
    }
}
