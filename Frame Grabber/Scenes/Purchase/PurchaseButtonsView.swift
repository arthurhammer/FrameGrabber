import Utility
import UIKit

class PurchaseButtonsView: UIStackView {

    @IBOutlet var purchaseButton: UIButton!
    @IBOutlet var restoreButton: UIButton!

    override func awakeFromNib() {
        super.awakeFromNib()
        configureViews()
    }

    private func configureViews() {
        purchaseButton.configureWithDefaultShadow()
        
        var purchaseButtonConfiguration = UIButton.Configuration.action()
        purchaseButtonConfiguration.baseForegroundColor = .white
        purchaseButtonConfiguration.titleTextAttributesTransformer = nil  // Don't use default fonts.
        purchaseButton.configuration = purchaseButtonConfiguration
        
        let purchaseWidthConstraint = purchaseButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 320)
        purchaseWidthConstraint.priority = .required - 1
        purchaseWidthConstraint.isActive = true
        
        restoreButton.configuration = .actionAccessory()
        
        // Avoid height jumping when activity indicator is shown.
        let restoreHeightConstraint = restoreButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 50)
        restoreHeightConstraint.priority = .defaultHigh
        restoreHeightConstraint.isActive = true
    }
}

// MARK: - Applying View Model

extension PurchaseButtonsView {
    
    func setup(
        withPurchaseButtonConfiguration purchaseButtonConfiguration: PurchaseViewModel.ButtonConfiguration,
        restoreButtonConfiguration: PurchaseViewModel.ButtonConfiguration
    ) {
        setupButton(
            purchaseButton,
            with: purchaseButtonConfiguration,
            titleFont: .preferredFont(forTextStyle: .headline),
            subtitleFont: .preferredFont(forTextStyle: .headline, weight: .regular)
        )
        
        setupButton(
            restoreButton,
            with: restoreButtonConfiguration,
            titleFont: .preferredFont(forTextStyle: .subheadline),
            subtitleFont: nil
        )
    }
    
    private func setupButton(
        _ button: UIButton,
        with viewModelConfiguration: PurchaseViewModel.ButtonConfiguration,
        titleFont: UIFont,
        subtitleFont: UIFont?
    ) {
        // Just setting the title on the configuration doesn't work, need to use the update handler.
        button.configurationUpdateHandler = { [weak self] button in
            var configuration = button.configuration
            configuration?.attributedTitle = self?.attributedText(for: viewModelConfiguration, titleFont: titleFont, subtitleFont: subtitleFont)
            configuration?.baseBackgroundColor = viewModelConfiguration.backgroundColor
            configuration?.showsActivityIndicator = viewModelConfiguration.isLoading
            button.isUserInteractionEnabled = viewModelConfiguration.isUserInteractionEnabled
            button.configuration = configuration
        }
        
        button.setNeedsUpdateConfiguration()
    }
    
    private func attributedText(
        for viewModelConfiguration: PurchaseViewModel.ButtonConfiguration,
        titleFont: UIFont,
        subtitleFont: UIFont?
    ) -> AttributedString? {
        
        guard let title = viewModelConfiguration.title else {
            return nil
        }
        
        var text = AttributedString(title)
        text.font = titleFont

        if let subtitle = viewModelConfiguration.subtitle {
            var subtitleText = AttributedString(" " + subtitle)
            subtitleText.font = subtitleFont
            text.append(subtitleText)
        }

        return text
    }
}
