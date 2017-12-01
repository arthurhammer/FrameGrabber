import UIKit

class VideoPlayerStatusControllerTMP: UIViewController {

    @IBOutlet var previewImageView: UIImageView!
    @IBOutlet var activitiyIndicator: UIActivityIndicatorView!
    @IBOutlet var errorButton: UIButton!

    var previewImage: UIImage? {
        didSet {
            guard isViewLoaded else { return }
            previewImageView.image = previewImage
        }
    }

    // Just give him player status maybe

    override func viewDidLoad() {
        super.viewDidLoad()
        configureViews()
    }

    private func configureViews() {
        view.backgroundColor = .mainBackground // TODO

        previewImageView.contentMode = .scaleAspectFit
        previewImageView.image = previewImage  // Image might have been set before `viewDidLoad`

        activitiyIndicator.isHidden = true
        errorButton.isHidden = true

        // Increase visibility on light backgrounds
        errorButton.layer.shadowOpacity = 1.0
        errorButton.layer.shadowColor = UIColor.black.cgColor
        errorButton.layer.shadowOffset = .zero
        errorButton.layer.shadowRadius = 1
    }
}
