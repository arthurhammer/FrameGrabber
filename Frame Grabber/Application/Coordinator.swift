import PhotoAlbums
import UIKit

class Coordinator: NSObject {

    let navigationController: NavigationController
    let albumsViewController: AlbumsViewController

    init(navigationController: NavigationController) {
        self.navigationController = navigationController

        guard let albumsViewController = navigationController.viewControllers.first as? AlbumsViewController else {
            fatalError("Wrong view controller")
        }

        self.albumsViewController = albumsViewController

        super.init()
    }

    func start() {
        showEmptyAlbum(animated: false)

        // Defer configuration to avoid triggering premature authorization dialogs.
        authorizeIfNecessary { [weak self] in
            self?.configureAlbums()
        }
    }

    // MARK: Authorizing

    private func authorizeIfNecessary(completion: @escaping () -> ()) {
        if PhotoLibraryAuthorizationController.needsAuthorization {
            DispatchQueue.main.async {
                self.showAuthorization(animated: true, completion: completion)
            }
        } else {
            completion()
        }
    }

    private func showAuthorization(animated: Bool, completion: @escaping () -> ()) {
        let storyboard = UIStoryboard(name: "Authorization", bundle: nil)

        guard let authorizationController = storyboard.instantiateInitialViewController() as? PhotoLibraryAuthorizationController else { fatalError("Wrong controller type") }

        authorizationController.didAuthorizeHandler = { [weak self] in
            self?.navigationController.dismiss(animated: true)
            completion()
        }

        authorizationController.isModalInPresentation = true
        navigationController.present(authorizationController, animated: animated)
    }

    // MARK: Showing Albums

    private func showEmptyAlbum(animated: Bool) {
        guard let albumViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: AlbumViewController.name) as? AlbumViewController else { fatalError("Wrong controller id or type") }
        albumViewController.navigationItem.largeTitleDisplayMode = .always
        albumViewController.defaultTitle = UserText.albumUnauthorizedTitle
        navigationController.pushViewController(albumViewController, animated: animated)
    }

    private func configureAlbums() {
        albumsViewController.albumsDataSource = AlbumsDataSource.default()

        if let albumViewController = navigationController.topViewController as? AlbumViewController {
            let type = albumViewController.settings.videoType
            albumViewController.album = AlbumsDataSource.fetchInitialAlbum(withVideoType: type)
        }
    }
}
