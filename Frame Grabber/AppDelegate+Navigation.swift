import UIKit

private let photoLibraryStoryboardId = "Main"
private let authorizationStoryboardId = String(describing: PhotoLibraryAuthorizationController.self)

extension AppDelegate {

    func showInitialController() {
        if PhotoLibraryAuthorizationController.needsAuthorization {
            showPhotoLibraryAuthorizationController()
        } else {
            showVideosController()
        }
    }

    private func showVideosController() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: photoLibraryStoryboardId)

        setRootViewController(controller, animated: true)
    }

    private func showPhotoLibraryAuthorizationController() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)

        let controller = storyboard.instantiateViewController(withIdentifier: authorizationStoryboardId)
        guard let authorizationController = controller as? PhotoLibraryAuthorizationController else { fatalError("Wrong controller id or type") }

        authorizationController.didAuthorizeHandler = { [weak self] in
            self?.showVideosController()
        }

        setRootViewController(authorizationController, animated: true)
    }
}

private extension AppDelegate {
    func setRootViewController(_ viewController: UIViewController, animated: Bool) {
        let set: (Bool) -> () = { _ in self.window?.rootViewController = viewController }

        if animated, let rootView = window?.rootViewController?.view {
            UIView.transition(from: rootView, to: viewController.view, duration: 0.35, options: .transitionCrossDissolve, completion: set)
        } else {
            set(true)
        }
    }
}
