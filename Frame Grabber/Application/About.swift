import Foundation

struct About {
    static let storeURL = URL(string: "https://apps.apple.com/app/id1434703541")
    static let storeReviewURL = URL(string: "https://apps.apple.com/app/id1434703541?action=write-review")
    static let sourceCodeURL = URL(string: "https://github.com/arthurhammer/FrameGrabber")
    static let contactAddress = "hi@arthurhammer.de"
    static let inAppPurchaseIdentifier = "de.arthurhammer.framegrabber.thankyou"
}

extension About {

    struct PrivacyPolicy {
        static let en = URL(string: "https://framegrabberapp.com/privacy/")
        static let de = URL(string: "https://framegrabberapp.com/datenschutz/")

        static var preferred: URL? {
            let language = Bundle.main.preferredLocalizations.first

            switch language {
            case "de":
                return PrivacyPolicy.de
            default:
                return PrivacyPolicy.en
            }
        }
    }
}
