import UIKit

extension UIAlertController {

    static func videoLoadingFailed(okHandler: ((UIAlertAction) -> ())? = nil) -> UIAlertController {
        let title = NSLocalizedString("alert.video-load.title", value: "Unable to Load Item", comment: "")
        let message = NSLocalizedString("alert.video-load.message", value: "Please check your network settings and make sure the format is supported on this device.", comment: "")
        return with(title: title, message: message, okHandler: okHandler)
    }

    static func playbackFailed(okHandler: ((UIAlertAction) -> ())? = nil) -> UIAlertController {
        let title = NSLocalizedString("alert.playback.title", value: "Cannot Play Item", comment: "")
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

    // MARK: In-App Purchase Errors

    static func purchaseNotAllowed(okHandler: ((UIAlertAction) -> ())? = nil) -> UIAlertController {
        let title = NSLocalizedString("alert.purchase.restore.notallowed.title", value: "Cannot Purchase Ice Cream", comment: "Alert title: The user is not authorized to make payments.")
        let message = NSLocalizedString("alert.purchase.notallowed.message", value: "In-App Purchases are not allowed on this device. Thank you for trying!", comment: "Alert message: The user is not authorized to make payments.")
        return with(title: title, message: message, okHandler: okHandler)
    }

    static func productNotFetched(okHandler: ((UIAlertAction) -> ())? = nil) -> UIAlertController {
        let title = NSLocalizedString("alert.purchase.notfetched.title", value: "Cannot Purchase Ice Cream", comment: "Alert title: The purchase can't proceed because the product has not yet been fetched, usually due to network errors.")
        let message = NSLocalizedString("alert.purchase.notfetched.message", value: "Please check your network settings and try again later.", comment: "Alert message: The purchase can't proceed because the product has not yet been fetched, usually due to network errors.")
        return with(title: title, message: message, okHandler: okHandler)
    }

    static func purchaseFailed(error: Error?, okHandler: ((UIAlertAction) -> ())? = nil) -> UIAlertController {
        // Unfortunately, `error.localizedDescription` does not seem to be localized, so
        // we use a generic message.
        let title = NSLocalizedString("alert.purchase.failed.title", value: "Cannot Purchase Ice Cream", comment: "Alert title: Purchasing failed.")
        let message = NSLocalizedString("alert.purchase.failed.message", value: "Please check your network settings and try again later. Thank you for your support!", comment: "Alert message: The purchase can't proceed because the product has not yet been fetched, usually due to network errors.")
        return with(title: title, message: message, okHandler: okHandler)
    }

    static func restoreNotAllowed(okHandler: ((UIAlertAction) -> ())? = nil) -> UIAlertController {
        let title = NSLocalizedString("alert.purchase.restore.notallowed.title", value: "Cannot Restore Your Purchase", comment: "Alert title: The user is not authorized to restore purchases.")
        let message = NSLocalizedString("alert.purchase.restore.notallowed.message", value: "In-App Purchases are not allowed on this device. Thank you for trying!", comment: "Alert message: The user is not authorized to restore purchases.")
        return with(title: title, message: message, okHandler: okHandler)
    }

    static func nothingToRestore(okHandler: ((UIAlertAction) -> ())? = nil) -> UIAlertController {
        let title = NSLocalizedString("alert.purchase.restore.empty.title", value: "Nothing to Restore", comment: "Alert title: Nothing to restore, the user has not previously purchased anything.")
        let message = NSLocalizedString("alert.purchase.restore.empty.message", value: "Looks like you haven't sent any ice cream yet!", comment: "Alert message: Nothing to restore, the user has not previously purchased anything. ")
        return with(title: title, message: message, okHandler: okHandler)
    }

    static func restoreFailed(error: Error, okHandler: ((UIAlertAction) -> ())? = nil) -> UIAlertController {
        let title = NSLocalizedString("alert.purchase.restore.failed.title", value: "Cannot Restore Your Purchase", comment: "Alert title: Restoring failed.")
        let message = NSLocalizedString("alert.purchase.restore.failed.message", value: "Please check your network settings and try again later. Thank you for your support!", comment: "Alert message: Restoring failed.")
        return with(title: title, message: message, okHandler: okHandler)
    }
}

// MARK: - Utility

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
