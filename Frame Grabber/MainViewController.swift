import UIKit
import Photos

class MainViewController: UIViewController {

    private var videoViewController: VideoViewController!
    private var videoLibraryViewController: VideoLibraryViewController!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .mainBackgroundColor

        if needsPhotosAccess {
            presentPhotosAccessController()
        } else {
            // Load videos only after making sure access is granted to avoid premature access dialogs.
            videoLibraryViewController.fetchVideos()
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let controller = segue.destination as? VideoViewController {
            videoViewController = controller
        } else if let controller = segue.destination as? VideoLibraryViewController {
            videoLibraryViewController = controller
            videoLibraryViewController.delegate = self
        }
    }
}

// MARK: - PhotosAccessViewControllerDelegate

extension MainViewController: PhotosAccessViewControllerDelegate {

    func didAuthorize() {
        dismiss(animated: true)
        videoLibraryViewController.fetchVideos()
    }
}

// MARK: - VideoLibraryViewControllerDelegate

extension MainViewController: VideoLibraryViewControllerDelegate {

    func didSelectVideo(_ video: Video) {
        videoViewController.video = video
    }
}

// MARK: - Private

private extension MainViewController {

    var needsPhotosAccess: Bool {
        return PHPhotoLibrary.authorizationStatus() != .authorized
    }

    func presentPhotosAccessController() {
        let id = String(describing: PhotosAccessViewController.self)
        let storyboard = UIStoryboard(name: id, bundle: nil)

        guard let photosAccessController = storyboard.instantiateViewController(withIdentifier: id) as? PhotosAccessViewController else {
            fatalError("Wrong controller identifier or type.")
        }

        photosAccessController.delegate = self
        present(photosAccessController, animated: true)
    }
}
