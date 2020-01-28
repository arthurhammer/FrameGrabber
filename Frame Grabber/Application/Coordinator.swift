import UIKit

class Coordinator: NSObject {

    let rootNavigationController: UINavigationController
    let albumsViewController: AlbumsViewController

    var currentAlbumViewController: AlbumViewController? {
        return rootNavigationController.topViewController as? AlbumViewController
    }

    init(window: UIWindow?) {
        self.rootNavigationController = window!.rootViewController as! UINavigationController
        self.albumsViewController = rootNavigationController.viewControllers.first as! AlbumsViewController

        super.init()

        configureInteractivePopGesture()
    }

    func start() {
        pushAlbumViewController(animated: false)

        authorizeIfNecessary { [weak self] in
            self?.configureAlbumViewControllers()
        }
    }

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
            self?.rootNavigationController.dismiss(animated: true) 
            completion()
        }

        if #available(iOS 13.0, *) {
            authorizationController.isModalInPresentation = true
        }

        rootNavigationController.present(authorizationController, animated: animated)
    }

    private func pushAlbumViewController(animated: Bool) {
        guard let albumViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: AlbumViewController.name) as? AlbumViewController else {
            fatalError("Wrong controller id or type")
        }
        albumViewController.navigationItem.largeTitleDisplayMode = .always
        rootNavigationController.pushViewController(albumViewController, animated: animated)
    }

    private func configureAlbumViewControllers() {
        // Defer configuring data sources until authorized to avoid triggering premature
        // authorization dialogs.
        currentAlbumViewController?.album = fetchInitialAlbum()
        albumsViewController.dataSource = AlbumsDataSource()
    }

    private func fetchInitialAlbum() -> FetchedAlbum? {
        let type = AlbumsDataSource.defaultSmartAlbumTypes.first ?? .smartAlbumVideos
        return FetchedAlbum.fetchSmartAlbums(with: [type], assetFetchOptions: .smartAlbumVideos()).first
    }

    private func configureInteractivePopGesture() {
        // On custom navigation transitions (without nav bar), UIKit seems to disable the
        // interactive pop gesture. Restore it by setting the delegate. But work around
        // the fact that the recognizer is nil until a second controller has been pushed.
        rootNavigationController.pushViewController(UIViewController(), animated: false)
        rootNavigationController.popViewController(animated: false)
        rootNavigationController.interactivePopGestureRecognizer?.delegate = self
    }
}

extension Coordinator: UIGestureRecognizerDelegate {

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        !(rootNavigationController.topViewController is PlayerViewController)
    }
}
