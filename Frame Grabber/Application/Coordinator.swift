import PhotoAlbums
import UIKit

class Coordinator: NSObject {

    let navigationController: NavigationController

    init(navigationController: NavigationController) {
        self.navigationController = navigationController
        super.init()
    }

    func start() {
        // Defer configuration to avoid triggering premature authorization dialogs.
        authorizeIfNecessary { [weak self] in
            self?.configureAlbum()
        }
    }

    // MARK: Authorizing

    private func authorizeIfNecessary(completion: @escaping () -> ()) {
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

        authorizationController.isModalInPresentation = true
        navigationController.present(authorizationController, animated: animated)
    }

    // MARK: Showing Albums

    private func configureAlbum() {
        guard let albumViewController = navigationController.topViewController as? AlbumViewController else { return }
        
        let filter = albumViewController.settings.videoTypesFilter
        albumViewController.album = AlbumsDataSource.fetchInitialAlbum(with: filter)
    }
}
