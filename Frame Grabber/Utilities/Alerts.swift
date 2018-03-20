import UIKit

extension UIAlertController {

    static func videoLoadingFailed(okHandler: ((UIAlertAction) -> ())? = nil) -> UIAlertController {
        let title = NSLocalizedString("Couldn't load video from iCloud.", comment: "")
        return genericController(withTitle: title, okHandler: okHandler)
    }

    static func playbackFailed(okHandler: ((UIAlertAction) -> ())? = nil) -> UIAlertController {
        let title = NSLocalizedString("Item couldn't be played.", comment: "")
        return genericController(withTitle: title, okHandler: okHandler)
    }

    static func imageGenerationFailed(okHandler: ((UIAlertAction) -> ())? = nil) -> UIAlertController {
        let title = NSLocalizedString("Sorry, couldn't grab image.", comment: "")
        return genericController(withTitle: title, okHandler: okHandler)
    }

    static func genericController(withTitle title: String?, message: String? = nil, preferredStyle: UIAlertControllerStyle = .alert, okHandler: ((UIAlertAction) -> ())? = nil) -> UIAlertController {
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
