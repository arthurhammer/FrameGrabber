import Photos
import UIKit

extension PHPhotoLibrary {

    /// Request read/write authorization optionally opening Settings if denied or restricted.
    static func requestReadWriteAuthorization(openingSettingsIfNeeded openSettings: Bool, completion: @escaping (PHAuthorizationStatus, Bool) -> ()) {
        let status = authorizationStatus(for: .readWrite)
        let isDenied = (status == .denied || status == .restricted)

        if isDenied && openSettings {
            UIApplication.shared.openSettings() { didOpen in
                completion(status, didOpen)
            }
            return
        }

        requestAuthorization(for: .readWrite) { status in
            DispatchQueue.main.async {
                completion(status, false)
            }
        }
    }
}
