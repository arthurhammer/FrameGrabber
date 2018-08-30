import UIKit

extension AppDelegate {

    private struct StoryboardId {
        static let authorization = String(describing: PhotoLibraryAuthorizationController.self)
        static let album = String(describing: AlbumViewController.self)
    }

    func showInitialScreen() {
        if PhotoLibraryAuthorizationController.needsAuthorization {
            showPhotoLibraryAuthorizationScreen(animated: false)
        } else {
            showMainScreen(animated: false)
        }
    }

    private func showPhotoLibraryAuthorizationScreen(animated: Bool) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)

        guard let authorizationController = storyboard.instantiateViewController(withIdentifier: StoryboardId.authorization) as? PhotoLibraryAuthorizationController else {
            fatalError("Wrong controller id or type")
        }

        authorizationController.didAuthorizeHandler = { [weak self] in
            self?.showMainScreen(animated: true)
        }

        setRootViewController(authorizationController, animated: animated)
    }

    private func showMainScreen(animated: Bool) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)

        guard let rootNavController = storyboard.instantiateInitialViewController() as? UINavigationController,
            let initialAlbumController = storyboard.instantiateViewController(withIdentifier: StoryboardId.album) as? AlbumViewController else {
                fatalError("Wrong controller id or type.")
        }

        // Show "all videos" album on launch (data fetched synchronously).
        if let initialAlbum = AlbumsDataSource.defaultSmartAlbumTypes.first,
            let album = FetchedAlbum.fetchSmartAlbums(with: [initialAlbum], assetFetchOptions: .smartAlbumVideos()).first {

            initialAlbumController.album = album
            initialAlbumController.navigationItem.largeTitleDisplayMode = .always
            rootNavController.pushViewController(initialAlbumController, animated: false)
        }

        setRootViewController(rootNavController, animated: animated)
    }
}

private extension AppDelegate {
    func setRootViewController(_ viewController: UIViewController, animated: Bool) {
        let set: (Bool) -> () = { _ in
            self.window?.rootViewController = viewController
        }

        if animated, let rootView = window?.rootViewController?.view {
            UIView.transition(from: rootView, to: viewController.view, duration: 0.35, options: .transitionCrossDissolve, completion: set)
        } else {
            set(true)
        }
    }
}
