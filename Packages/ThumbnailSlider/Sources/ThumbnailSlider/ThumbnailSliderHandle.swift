import CoreMedia
import UIKit

class ThumbnailSliderHandle: UIView {

    var minimumTouchSize = CGSize(width: 44, height: 44)

    var touchTarget: CGRect {
        frame.increased(to: minimumTouchSize)
    }

    var isEnabled: Bool = true {
        didSet { updateViews() }
    }

    var handleColor: UIColor = .white {
        didSet { updateViews() }
    }

    var disabledHandleColor: UIColor = .systemGray4 {
        didSet { updateViews() }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureViews()
    }

    private func configureViews() {
        isUserInteractionEnabled = false
        clipsToBounds = false
        
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.2
        layer.shadowRadius = 6
        layer.shadowOffset = .zero
        
        updateViews()
    }

    private func updateViews() {
        backgroundColor = isEnabled ? handleColor : disabledHandleColor
    }
}
