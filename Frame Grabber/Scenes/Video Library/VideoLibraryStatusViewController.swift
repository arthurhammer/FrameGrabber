import UIKit
import Photos

// TODO: Localized strings

enum VideoLibraryStatus {
    case accessNotDetermined
    case accessDenied
    case noVideos
    case ok
}

extension VideoLibraryStatus {

    var message: StatusMessage? {
        switch self {

        case .accessNotDetermined:
            return StatusMessage(title: NSLocalizedString("Frame Grabber", comment: ""),
                                 message: NSLocalizedString("Get started by allowing access to your Photo Library.", comment: ""),
                                 action: NSLocalizedString("Allow Access", comment: ""))

        case .accessDenied:
            return StatusMessage(title: NSLocalizedString("Frame Grabber", comment: ""),
                                 message: NSLocalizedString("Frame Grabber needs access to your Photo Library. You can allow this in Settings.", comment: ""),
                                 action: NSLocalizedString("Open Settings", comment: ""))

        case .noVideos:
            return StatusMessage(title: NSLocalizedString("No Videos", comment: ""),
                                 message: NSLocalizedString("Get started by taking a video.", comment: ""),
                                 action: nil)

        case .ok:
            return nil
        }
    }
}

protocol VideoLibraryStatusViewControllerDelegate: class {
    func didAuthorize()
}

/// Handles the Photo Library user authorization and displays the current status of authorization and video library.
class VideoLibraryStatusViewController: UIViewController {

    weak var delegate: VideoLibraryStatusViewControllerDelegate?

    override var nibName: String? {
        return StatusView.className
    }

    var statusView: StatusView {
        return view as! StatusView
    }

    var status: VideoLibraryStatus {
        switch PHPhotoLibrary.authorizationStatus() {
        case .notDetermined:
            return .accessNotDetermined
        case .denied, .restricted:
            return .accessDenied
        case .authorized where isEmpty:
            return .noVideos
        case .authorized:
            return .ok
        }
    }

    var isAuthorized: Bool {
        return PHPhotoLibrary.isAuthorized
    }

    var isEmpty = true {
        didSet {
            updateViews()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureViews()
        updateViews()
    }

    @objc func requestAuthorization() {
        PHPhotoLibrary.requestAuthorization(openingSettingsIfNecessary: true) { status, _ in
            self.updateViews()

            if case .authorized = status {
                self.delegate?.didAuthorize()
            }
        }
    }

    private func configureViews() {
        statusView.button.addTarget(self, action: #selector(requestAuthorization), for: .touchUpInside)
    }

    private func updateViews() {
        statusView.displayMessage(status.message)
    }
}
