import UIKit

class PurchaseButtonsView: UIStackView {

    @IBOutlet var purchaseButton: UIButton!
    @IBOutlet var restoreButton: UIButton!

    override func awakeFromNib() {
        super.awakeFromNib()
        configureViews()
    }

    private func configureViews() {
        purchaseButton.configureAsActionButton(minimumWidth: 300)
        restoreButton.configureDynamicTypeLabel()
    }
}

// MARK: - Configuring

extension PurchaseButtonsView {

    func configure(with state: PurchaseViewController.State, price: String?) {
        
        if let price = price {
            let text = NSMutableAttributedString(string: UserText.IAPAction)
            let spacer = NSAttributedString(string: "  ")
            
            let price = NSAttributedString(string: price, attributes: [
                .font: UIFont.preferredFont(forTextStyle: .headline, weight: .regular)
            ])
            
            text.append(spacer)
            text.append(price)
            purchaseButton.setAttributedTitle(text, for: .normal)
        } else {
            purchaseButton.setTitle(UserText.IAPAction, for: .normal)
        }
    }
}
