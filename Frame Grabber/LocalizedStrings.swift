import Foundation

extension String {
    static let okAlertAction = NSLocalizedString("alert.actions.ok", comment: "OK on error alert")
    static let cancelAlertAction = NSLocalizedString("alert.actions.cancel", comment: "Cancel on error alert")
    static let retryAlertAction = NSLocalizedString("alert.actions.retry", comment: "Retry alert action")

    static let defaultAlertTitle = NSLocalizedString("alert.error.title", comment: "Default alert title for errors")
    static let defaultAlertMessage = NSLocalizedString("alert.error.message", comment: "Default alert message for errors when no `Error` provided")

    static let imageExportFailedTitle = NSLocalizedString("alert.error.message", comment: "Default alert message for errors when no `Error` provided")
    static let imageExportFailedMessage = NSLocalizedString("alert.error.message", comment: "Default alert message for errors when no `Error` provided")
}
