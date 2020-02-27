import Foundation

struct About {
    static let storeURL = URL(string: "itms-apps://itunes.apple.com/app/id1434703541?ls=1&mt=8")
    static let storeReviewURL = URL(string: "itms-apps://itunes.apple.com/app/id1434703541?ls=1&mt=8&action=write-review")
    static let sourceCodeURL = URL(string: "https://github.com/arthurhammer/FrameGrabber")
    static let contactAddress = "hi@arthurhammer.de"
    static let inAppPurchaseIdentifier = "de.arthurhammer.framegrabber.thankyou"
}

extension About {

    struct PrivacyPolicy {
        static let en = URL(string: "https://arthurhammer.github.io/FrameGrabber")
        static let de = URL(string: "https://arthurhammer.github.io/FrameGrabber/de")

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
