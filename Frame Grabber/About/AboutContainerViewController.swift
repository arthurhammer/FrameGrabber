import UIKit

class AboutContainerViewController: UIViewController {

    var hasPurchased: Bool {
        paymentsManager.hasPurchasedProduct(withId: inAppPurchaseId)
    }

    private let app = UIApplication.shared
    private let paymentsManager = StorePaymentsManager.shared
    private let inAppPurchaseId = About.inAppPurchaseIdentifier
    private let reviewURL = About.storeReviewURL

    @IBOutlet private var rateButton: UIButton!
    @IBOutlet private var iceCreamButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        configureViews()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateViews()

        transitionCoordinator?.animate(alongsideTransition: { [weak self] _ in
            self?.styleNavigationBar()
        }, completion: { [weak self] _ in
            self?.styleNavigationBar()
        })
    }

    @IBAction private func done() {
        dismiss(animated: true)
    }

    @IBAction private func rate() {
        guard let url = reviewURL,
            app.canOpenURL(url) else { return }

        app.open(url)
    }

    private func configureViews() {
        rateButton.tintColor = .systemGroupedBackground
        rateButton.backgroundColor = Style.Color.mainTint
        rateButton.layer.cornerRadius = Style.Size.buttonCornerRadius

        updateViews()
    }

    private func updateViews() {
        let title = hasPurchased
            ? NSLocalizedString("about.icecream.purchased", value: "Thank You :)", comment: "Container view button message when in-app purchase was purchased.")
            : NSLocalizedString("about.icecream.notpurchased", value: "Ice Cream", comment: "Container view button message when in-app purchase was not purchased.")

        iceCreamButton.setTitle(title, for: .normal)
    }

    private func styleNavigationBar() {
        let bar = navigationController?.navigationBar
        bar?.tintColor = nil
        bar?.shadowImage = nil
        bar?.setBackgroundImage(nil, for: .default)
    }
}
