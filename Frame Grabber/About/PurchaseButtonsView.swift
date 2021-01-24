import UIKit

class PurchaseButtonsView: UIStackView {

    @IBOutlet var purchaseButton: ActivityButton!
    @IBOutlet var restoreButton: UIButton!

    override func awakeFromNib() {
        super.awakeFromNib()
        configureViews()
    }

    private func configureViews() {
        purchaseButton.activityIndicator.color = .white
        purchaseButton.configureAsActionButton(minimumWidth: 300)
        restoreButton.configureDynamicTypeLabel()
    }
}

// MARK: - Configuring

extension PurchaseButtonsView {

    func configure(with state: PurchaseViewController.State, price: String?) {
        switch state {

        case .fetchingProducts, .purchasing, .restoring:
            isHidden = false
            purchaseButton.isShowingActivity = true
            restoreButton.isEnabled = false

        case .productsNotFetched, .readyToPurchase:
            isHidden = false
            purchaseButton.isShowingActivity = false
            restoreButton.isEnabled = true

            if let price = price {
                purchaseButton.dormantTitle = String.localizedStringWithFormat(UserText.IAPActionWithPriceFormat, price)
            } else {
                purchaseButton.dormantTitle = UserText.IAPActionWithoutPrice
            }

        case .purchased:
            isHidden = true
            purchaseButton.dormantTitle = nil
        }
    }
}
