import UIKit

/// Static factories for UIAlertController alerts.
extension UIAlertController {
    
    static func videoLoadingFailed(okHandler: ((UIAlertAction) -> ())? = nil) -> UIAlertController {
        with(
            title: Localized.alertVideoLoadFailedTitle,
            message: Localized.alertVideoLoadFailedMessage,
            okHandler: okHandler
        )
    }
    
    static func playbackFailed(okHandler: ((UIAlertAction) -> ())? = nil) -> UIAlertController {
        with(
            title: Localized.alertPlaybackFailedTitle,
            message: Localized.alertPlaybackFailedMessage,
            okHandler: okHandler
        )
    }
    
    static func filePickingFailed(okHandler: ((UIAlertAction) -> ())? = nil) -> UIAlertController {
        with(
            title: Localized.alertFilePickingFailedTitle,
            message: Localized.alertFilePickingFailedMessage,
            okHandler: okHandler
        )
    }
    
    static func frameExportFailed(okHandler: ((UIAlertAction) -> ())? = nil) -> UIAlertController {
        with(
            title: Localized.alertFrameExportFailedTitle,
            message: Localized.alertFrameExportFailedMessage,
            okHandler: okHandler
        )
    }
    
    static func savingToPhotosFailed(okHandler: ((UIAlertAction) -> ())? = nil) -> UIAlertController {
        with(
            title: Localized.alertFrameExportFailedTitle,
            message: Localized.alertFrameExportFailedMessage,
            okHandler: okHandler
        )
    }
    
    static func videoRecordingUnavailable(okHandler: ((UIAlertAction) -> ())? = nil) -> UIAlertController {
        with(
            title: Localized.videoRecordingUnavailableTitle,
            message: Localized.videoRecordingUnavailableMessage,
            okHandler: okHandler
        )
    }
    
    /// By default, the open settings action opens the app's Settings.
    static func videoRecordingDenied(
        okHandler: ((UIAlertAction) -> ())? = nil,
        openSettingsHandler: ((UIAlertAction) -> ())? = { _ in UIApplication.shared.openSettings() }
    ) -> UIAlertController {
        let alert = UIAlertController(
            title: Localized.videoRecordingDeniedTitle,
            message: Localized.videoRecordingDeniedMessage,
            preferredStyle: .alert
        )
        
        alert.addAction(.openSettings(handler: openSettingsHandler))
        alert.addAction(.ok())
        
        return alert
    }
    
    static func recordingVideoFailed(okHandler: ((UIAlertAction) -> ())? = nil) -> UIAlertController {
        with(
            title: Localized.videoRecordingFailedTitle,
            message: Localized.videoRecordingFailedMessage,
            okHandler: okHandler
        )
    }
    
    static func mailNotAvailable(contactAddress: String, okHandler: ((UIAlertAction) -> ())? = nil) -> UIAlertController {
        with(
            title: Localized.alertMailUnavailableTitle,
            message: String.localizedStringWithFormat(Localized.alertMailUnavailableMessageFormat, contactAddress),
            okHandler: okHandler
        )
    }
}


// MARK: - Purchase

extension UIAlertController {
    static func purchaseNotAllowed(okHandler: ((UIAlertAction) -> ())? = nil) -> UIAlertController {
        with(
            title: Localized.Purchase.purchaseUnauthorized,
            message: Localized.Purchase.purchaseUnauthorizedMessage,
            okHandler: okHandler
        )
    }

    static func productNotFetched(okHandler: ((UIAlertAction) -> ())? = nil) -> UIAlertController {
        with(
            title: Localized.Purchase.purchaseUnavailable,
            message: Localized.Purchase.purchaseUnavailableMessage,
            okHandler: okHandler
        )
    }

    static func purchaseFailed(error: Error?, okHandler: ((UIAlertAction) -> ())? = nil) -> UIAlertController {
        // `error.localizedDescription` does not seem to be localized, so we use a generic
        // message.
        with(
            title: Localized.Purchase.purchaseFailed,
            message: Localized.Purchase.purchaseFailedMessage,
            okHandler: okHandler
        )
    }

    static func restoreNotAllowed(okHandler: ((UIAlertAction) -> ())? = nil) -> UIAlertController {
        with(
            title: Localized.Purchase.restoreUnauthorized,
            message: Localized.Purchase.restoreUnauthorizedMessage,
            okHandler: okHandler
        )
    }

    static func nothingToRestore(okHandler: ((UIAlertAction) -> ())? = nil) -> UIAlertController {
        with(
            title: Localized.Purchase.nothingToRestore,
            message: Localized.Purchase.nothingToRestoreMessage,
            okHandler: okHandler
        )
    }

    static func restoreFailed(error: Error, okHandler: ((UIAlertAction) -> ())? = nil) -> UIAlertController {
        with(
            title: Localized.Purchase.restoreFailed,
            message: Localized.Purchase.restoreFailedMessage,
            okHandler: okHandler
        )
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
        UIAlertAction(title: Localized.okAction, style: .default, handler: handler)
    }

    static func cancel(handler: ((UIAlertAction) -> ())? = nil) -> UIAlertAction {
        UIAlertAction(title: Localized.cancelAction, style: .cancel, handler: handler) 
    }
    
    static func openSettings(handler: ((UIAlertAction) -> ())? = nil) -> UIAlertAction {
        UIAlertAction(title: Localized.openSettingsAction, style: .default, handler: handler)
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
