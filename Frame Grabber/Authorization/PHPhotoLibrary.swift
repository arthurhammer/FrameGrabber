import Photos
import UIKit

extension PHPhotoLibrary {

    /// Request read/write authorization optionally opening Settings if denied or restricted.
    static func requestReadWriteAuthorization(openingSettingsIfNeeded openSettings: Bool, completion: @escaping (PHAuthorizationStatus, Bool) -> ()) {
        let status = readWriteAuthorizationStatus
        let isDenied = (status == .denied || status == .restricted)

        if isDenied && openSettings {
            UIApplication.shared.openSettings() { didOpen in
                completion(status, didOpen)
            }
            return
        }

        requestReadWriteAuthorization { status in
            DispatchQueue.main.async {
                completion(status, false)
            }
        }
    }
}

extension PHPhotoLibrary {

    static var readWriteAuthorizationStatus: PHAuthorizationStatus {
        if #available(iOS 14, *) {
            return authorizationStatus(for: .readWrite)
        } else {
            return authorizationStatus()
        }
    }

    static func requestReadWriteAuthorization(handler: @escaping (PHAuthorizationStatus) -> Void) {
        if #available(iOS 14, *) {
            requestAuthorization(for: .readWrite, handler: handler)
        } else {
            requestAuthorization(handler)
        }
    }
}

private extension UIApplication {

    /// Open the app's settings in Settings.
    func openSettings(completionHandler: ((Bool) -> ())? = nil) {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString),
            canOpenURL(settingsUrl) else {

                completionHandler?(false)
                return
        }

        open(settingsUrl, options: [:], completionHandler: completionHandler)
    }
}
