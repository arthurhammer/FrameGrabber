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
        didSet { disabledOverlay.backgroundColor = disabledTintColor }
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

    private lazy var disabledOverlay: UIView = {
        let view = UIView(frame: bounds)
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.backgroundColor = disabledTintColor
        return view
    }()

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
    }

    func makeThumbnails(withAspectRatio aspectRatio: CGSize) {
        clearThumbnails()

        guard let thumbnailSize = aspectRatio.aspectFitting(height: bounds.height),
            thumbnailSize.width != 0 else { return }

        let amount = Int(ceil(bounds.width / thumbnailSize.width))

        (0..<amount).forEach { _ in
            let imageView = ThumbnailImageView()
            imageView.contentMode = .scaleAspectFill
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
        addSubview(disabledOverlay)
        updateViews()
    }

    private func updateViews() {
        disabledOverlay.isHidden = isEnabled
    }
}
