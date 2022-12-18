import UIKit

extension UIApplication {

    /// Open the app's settings in Settings.
    public func openSettings(completionHandler: ((Bool) -> ())? = nil) {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString),
            canOpenURL(settingsUrl) else {

                completionHandler?(false)
                return
        }

        open(settingsUrl, options: [:], completionHandler: completionHandler)
    }
}
