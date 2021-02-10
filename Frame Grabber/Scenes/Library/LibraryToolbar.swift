import UIKit

class LibraryToolbar: UIView {
    
    @IBOutlet var importButton: UIButton!
    
    var importButtonVisualEffectView: UIVisualEffectView? {
        importButton.superview?.superview as? UIVisualEffectView
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        configureViews()
    }

    private func configureViews() {
        importButtonVisualEffectView?.clipsToBounds = true
        importButtonVisualEffectView?.layer.cornerRadius = Style.buttonCornerRadius
        importButtonVisualEffectView?.layer.cornerCurve = .continuous
        
        importButton.layer.cornerRadius = Style.buttonCornerRadius
        importButton.layer.cornerCurve = .continuous

        importButton.configureDynamicTypeLabel()
    }
}
