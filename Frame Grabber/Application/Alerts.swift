import UIKit

extension UIAlertController {

    static func videoLoadingFailed(okHandler: ((UIAlertAction) -> ())? = nil) -> UIAlertController {
        let title = NSLocalizedString("alert.video-load.title", value: "Unable to Load Video", comment: "")
        let message = NSLocalizedString("alert.video-load.message", value: "Please check your network settings and make sure the video format is supported on this device.", comment: "")
        return with(title: title, message: message, okHandler: okHandler)
    }

    static func playbackFailed(okHandler: ((UIAlertAction) -> ())? = nil) -> UIAlertController {
        let title = NSLocalizedString("alert.playback.title", value: "Cannot Play Video", comment: "")
        let message = NSLocalizedString("alert.playback.message", value: "There was an error during playback.", comment: "")
        return with(title: title, message: message, okHandler: okHandler)
    }

    static func imageGenerationFailed(okHandler: ((UIAlertAction) -> ())? = nil) -> UIAlertController {
        let title = NSLocalizedString("alert.image-generation.title", value: "Unable to Export Image", comment: "")
        let message = NSLocalizedString("alert.image-generation.message", value: "There was an error while generating the image.", comment: "")
        return with(title: title, message: message, okHandler: okHandler)
    }

    static func mailNotAvailable(contactAddress: String, okHandler: ((UIAlertAction) -> ())? = nil) -> UIAlertController {
        let title = NSLocalizedString("alert.mail.title", value: "This Device Can't Send Emails", comment: "")
        let messageFormat = NSLocalizedString("alert.mail.message", value: "You can reach me at %@", comment: "E-mail address")
        let message = String.localizedStringWithFormat(messageFormat, contactAddress)
        return with(title: title, message: message, okHandler: okHandler)
    }
}

extension UIAlertController {
    static func with(title: String?, message: String? = nil, preferredStyle: UIAlertController.Style = .alert, okHandler: ((UIAlertAction) -> ())? = nil) -> UIAlertController {
        let controller = UIAlertController(title: title, message: message, preferredStyle: preferredStyle)
        controller.addAction(.ok(handler: okHandler))
        return controller
    }
}

extension UIAlertAction {
    static func ok(handler: ((UIAlertAction) -> ())? = nil) -> UIAlertAction {
        let title = NSLocalizedString("alert.ok", value: "OK", comment: "")
        return UIAlertAction(title: title, style: .default, handler: handler)
    }
}

extension UIViewController {
    func presentAlert(_ controller: UIAlertController, animated: Bool = true) {
        present(controller, animated: animated)
    }
}
