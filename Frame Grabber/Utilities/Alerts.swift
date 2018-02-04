import UIKit

extension UIAlertController {

    static func videoLoadingFailed(okHandler: ((UIAlertAction) -> ())? = nil) -> UIAlertController {
        let title = NSLocalizedString("Couldn't load video from iCloud.", comment: "")
        let okTitle = NSLocalizedString("OK", comment: "")

        let controller = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        let ok = UIAlertAction(title: okTitle, style: .default, handler: okHandler)
        controller.addAction(ok)

        return controller
    }

    static func playbackFailed(okHandler: ((UIAlertAction) -> ())? = nil) -> UIAlertController {
        let title = NSLocalizedString("Item couldn't be played.", comment: "")
        let okTitle = NSLocalizedString("OK", comment: "")

        let controller = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        let ok = UIAlertAction(title: okTitle, style: .default, handler: okHandler)
        controller.addAction(ok)

        return controller
    }
}
