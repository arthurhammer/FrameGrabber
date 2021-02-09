import UIKit

/// Static factories for UIAlertController alerts.
extension UIAlertController {

    static func videoLoadingFailed(okHandler: ((UIAlertAction) -> ())? = nil) -> UIAlertController {
        with(title: UserText.alertVideoLoadFailedTitle,
             message: UserText.alertVideoLoadFailedMessage,
             okHandler: okHandler)
    }

    static func playbackFailed(okHandler: ((UIAlertAction) -> ())? = nil) -> UIAlertController {
        with(title: UserText.alertPlaybackFailedTitle,
             message: UserText.alertPlaybackFailedMessage,
             okHandler: okHandler)
    }
    
    static func filePickingFailed(okHandler: ((UIAlertAction) -> ())? = nil) -> UIAlertController {
        with(title: UserText.alertFilePickingFailedTitle,
             message: UserText.alertFilePickingFailedMessage,
             okHandler: okHandler)
    }

    static func frameExportFailed(okHandler: ((UIAlertAction) -> ())? = nil) -> UIAlertController {
        with(title: UserText.alertFrameExportFailedTitle,
             message: UserText.alertFrameExportFailedMessage,
             okHandler: okHandler)
    }
    
    static func savingToPhotosFailed(okHandler: ((UIAlertAction) -> ())? = nil) -> UIAlertController {
        with(title: UserText.alertFrameExportFailedTitle,
             message: UserText.alertFrameExportFailedMessage,
             okHandler: okHandler)
    }
    
    
    static func videoRecordingUnavailable(okHandler: ((UIAlertAction) -> ())? = nil) -> UIAlertController {
        with(title: UserText.videoRecordingUnavailableTitle,
             message: UserText.videoRecordingUnavailableMessage,
             okHandler: okHandler)
    }
    
    static func videoRecordingDenied(okHandler: ((UIAlertAction) -> ())? = nil) -> UIAlertController {
        with(title: UserText.videoRecordingDeniedTitle,
             message: UserText.videoRecordingDeniedMessage,
             okHandler: okHandler)
    }
    
    static func recordingVideoFailed(okHandler: ((UIAlertAction) -> ())? = nil) -> UIAlertController {
        with(title: UserText.videoRecordingFailedTitle,
             message: UserText.videoRecordingFailedMessage,
             okHandler: okHandler)
    }

    static func mailNotAvailable(contactAddress: String, okHandler: ((UIAlertAction) -> ())? = nil) -> UIAlertController {
        with(title: UserText.alertMailUnavailableTitle,
             message: String.localizedStringWithFormat(UserText.alertMailUnavailableMessageFormat, contactAddress),
             okHandler: okHandler)
    }

    // MARK: In-App Purchase Errors

    static func purchaseNotAllowed(okHandler: ((UIAlertAction) -> ())? = nil) -> UIAlertController {
        with(title: UserText.alertIAPUnauthorizedTitle,
             message: UserText.alertIAPUnauthorizedMessage,
             okHandler: okHandler)
    }

    static func productNotFetched(okHandler: ((UIAlertAction) -> ())? = nil) -> UIAlertController {
        with(title: UserText.alertIAPUnavailableTitle,
             message: UserText.alertIAPUnavailableMessage,
             okHandler: okHandler)
    }

    static func purchaseFailed(error: Error?, okHandler: ((UIAlertAction) -> ())? = nil) -> UIAlertController {
        // `error.localizedDescription` does not seem to be localized, so we use a generic
        // message.
        with(title: UserText.alertIAPFailedTitle,
             message: UserText.alertIAPFailedMessage,
             okHandler: okHandler)
    }

    static func restoreNotAllowed(okHandler: ((UIAlertAction) -> ())? = nil) -> UIAlertController {
        with(title: UserText.alertIAPRestoreUnauthorizedTitle,
             message: UserText.alertIAPRestoreUnauthorizedMessage,
             okHandler: okHandler)
    }

    static func nothingToRestore(okHandler: ((UIAlertAction) -> ())? = nil) -> UIAlertController {
        with(title: UserText.alertIAPRestoreEmptyTitle,
             message: UserText.alertIAPRestoreEmptyMessage,
             okHandler: okHandler)
    }

    static func restoreFailed(error: Error, okHandler: ((UIAlertAction) -> ())? = nil) -> UIAlertController {
        with(title: UserText.alertIAPRestoreFailedTitle,
             message: UserText.alertIAPRestoreFailedMessage,
             okHandler: okHandler)
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
        UIAlertAction(title: UserText.okAction, style: .default, handler: handler)
    }

    static func cancel(handler: ((UIAlertAction) -> ())? = nil) -> UIAlertAction {
        UIAlertAction(title: UserText.cancelAction, style: .cancel, handler: handler) 
    }
}

extension UIAlertController {
    func addActions(_ actions: [UIAlertAction]) {
        actions.forEach(addAction)
    }
}

extension UIViewController {
    func presentAlert(_ controller: UIAlertController, animated: Bool = true) {
        present(controller, animated: animated)
    }
}
