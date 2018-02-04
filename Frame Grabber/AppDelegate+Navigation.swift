import UIKit

private let photoLibraryStoryboardId = "Main"
private let authorizationStoryboardId = String(describing: PhotoLibraryAuthorizationController.self)

extension AppDelegate {

    func showInitialController() {
        if PhotoLibraryAuthorizationController.needsAuthorization {
            showPhotoLibraryAuthorizationController()
        } else {
            showVideoLibraryController()
        }
    }

    private func showVideoLibraryController() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        window?.rootViewController = storyboard.instantiateViewController(withIdentifier: photoLibraryStoryboardId)
    }

    private func showPhotoLibraryAuthorizationController() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)

        let controller = storyboard.instantiateViewController(withIdentifier: authorizationStoryboardId)
        guard let authorizationController = controller as? PhotoLibraryAuthorizationController else { fatalError("Wrong controller id or type") }

        authorizationController.didAuthorizeHandler = { [weak self] in
            self?.showVideoLibraryController()
        }

        window?.rootViewController = authorizationController
    }
}
