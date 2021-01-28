import PhotoAlbums
import UIKit

class Coordinator: NSObject {

    let navigationController: NavigationController
    let albumViewController: AlbumViewController

    init(navigationController: NavigationController) {
        guard let albumViewController = navigationController.topViewController as? AlbumViewController else { fatalError("Wrong root controller or type.") }
        
        self.navigationController = navigationController
        self.albumViewController = albumViewController
        
        super.init()
    }

    func start() {
        albumViewController.delegate = self
        // Show placeholder title until authorized.
        albumViewController.defaultTitle =  UserText.albumUnauthorizedTitle
        
        showAuthorizationIfNecessary { [weak self] in
            // Defer configuration to avoid triggering premature authorization dialogs.
            self?.configureAlbum()
        }
    }

    // MARK: Authorizing

    private func showAuthorizationIfNecessary(completion: @escaping () -> ()) {
        if AuthorizationController.needsAuthorization {
            DispatchQueue.main.async {
                self.showAuthorization(animated: true, completion: completion)
            }
        } else {
            completion()
        }
    }

    private func showAuthorization(animated: Bool, completion: @escaping () -> ()) {
        let storyboard = UIStoryboard(name: "Authorization", bundle: nil)

        guard let authorizationController = storyboard.instantiateInitialViewController() as? AuthorizationController else { fatalError("Wrong controller type") }

        authorizationController.didAuthorizeHandler = { [weak self] in
            self?.navigationController.dismiss(animated: true)
            completion()
        }
        
        authorizationController.modalPresentationStyle = .formSheet
        authorizationController.isModalInPresentation = true
        navigationController.present(authorizationController, animated: animated)
    }

    // MARK: Showing Albums

    private func configureAlbum() {
        // Show default title again.
        albumViewController.defaultTitle = UserText.albumDefaultTitle
        albumViewController.albumsDataSource = AlbumsDataSource.default()
        
        if let initialCollection = AlbumsDataSource.fetchInitialAssetCollection() {
            let album = AnyAlbum(assetCollection: initialCollection)
            albumViewController.setSourceAlbum(album)
        }
    }

// MARK: - AlbumViewControllerDelegate

extension Coordinator: AlbumViewControllerDelegate {
    
    func controllerDidSelectFilePicker(_ controller: AlbumViewController) {
        showFilePicker()
    }
}

// MARK: - File Picker

extension Coordinator: UIDocumentPickerDelegate {
    
    private func showFilePicker() {
        if #available(iOS 14.0, *) {
            let picker = UIDocumentPickerViewController(
                forOpeningContentTypes: [.movie],
                asCopy: true
            )
            picker.shouldShowFileExtensions = true
            picker.delegate = self
            navigationController.showDetailViewController(picker, sender: nil)
        }
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let editor = UIStoryboard(name: "Editor", bundle: nil).instantiateInitialViewController() as? EditorViewController else { return }
        guard let url = urls.first else { return }
        editor.videoController = VideoController(source: .url(url), previewImage: nil)
        navigationController.show(editor, sender: nil)
}
