import UIKit

extension UIAlertController {

    static func videoLoadingFailed(okHandler: ((UIAlertAction) -> ())? = nil) -> UIAlertController {
        let title = NSLocalizedString("Couldn't load video from iCloud.", comment: "")
        return with(title: title, okHandler: okHandler)
    }

    static func playbackFailed(okHandler: ((UIAlertAction) -> ())? = nil) -> UIAlertController {
        let title = NSLocalizedString("Item couldn't be played.", comment: "")
        return with(title: title, okHandler: okHandler)
    }

    static func imageGenerationFailed(okHandler: ((UIAlertAction) -> ())? = nil) -> UIAlertController {
        let title = NSLocalizedString("Sorry, couldn't grab image.", comment: "")
        return with(title: title, okHandler: okHandler)
    }

    static func mailNotAvailable(contactAddress: String, okHandler: ((UIAlertAction) -> ())? = nil) -> UIAlertController {
        let title = NSLocalizedString("This device can't send emails.", comment: "")
        let messageFormat = NSLocalizedString("You can reach us at %@", comment: "")
        let message = String(format: messageFormat, arguments: [contactAddress])

        return with(title: title, message: message)
    }
}

extension UIAlertController {
    static func with(title: String?, message: String? = nil, preferredStyle: UIAlertControllerStyle = .alert, okHandler: ((UIAlertAction) -> ())? = nil) -> UIAlertController {
        let controller = UIAlertController(title: title, message: message, preferredStyle: preferredStyle)
        controller.addAction(.ok(handler: okHandler))
        return controller
    }
}

extension UIAlertAction {
    static func ok(handler: ((UIAlertAction) -> ())? = nil) -> UIAlertAction {
        let title = NSLocalizedString("OK", comment: "")
        return UIAlertAction(title: title, style: .default, handler: handler)
    }
}

extension UIViewController {
    func presentAlert(_ controller: UIAlertController, animated: Bool = true) {
        present(controller, animated: animated)
    }
}
