import UIKit

class PurchaseFeatureView: UIStackView {
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var descriptionLabel: UILabel!
}

class PurchaseFeaturesView: UIStackView {

    @IBOutlet var mainFeatureView: PurchaseFeatureView!
    @IBOutlet var firstFeatureView: PurchaseFeatureView!
    @IBOutlet var secondFeatureView: PurchaseFeatureView!
    @IBOutlet var thirdFeatureView: PurchaseFeatureView!

    func setMinorFeaturesHidden(_ hidden: Bool) {
        [firstFeatureView, secondFeatureView, thirdFeatureView].forEach {
            $0.isHidden = hidden
        }
    }
}

// MARK: - Configuration

extension PurchaseFeaturesView {

    func configure(with state: PurchaseViewController.State) {
        switch state {

        case .productsNotFetched, .fetchingProducts, .restoring, .readyToPurchase, .purchasing:
            setMinorFeaturesHidden(false)
            mainFeatureView.titleLabel.text = UserText.IAPNotPurchasedTitle
            mainFeatureView.descriptionLabel.text = UserText.IAPNotPurchasedMessage

        case .purchased:
            setMinorFeaturesHidden(true)
            mainFeatureView.titleLabel.text = UserText.IAPPurchasedTitle
            mainFeatureView.descriptionLabel.text = UserText.IAPPurchasedMessage
        }

        firstFeatureView.titleLabel.text = UserText.IAPFirstFeatureTitle
        firstFeatureView.descriptionLabel.text = UserText.IAPFirstFeatureMessage
        secondFeatureView.titleLabel.text = UserText.IAPSecondFeatureTitle
        secondFeatureView.descriptionLabel.text = UserText.IAPSecondFeatureMessage
        thirdFeatureView.titleLabel.text = UserText.IAPThirdFeatureTitle
        thirdFeatureView.descriptionLabel.text = UserText.IAPThirdFeatureMessage
    }
}
