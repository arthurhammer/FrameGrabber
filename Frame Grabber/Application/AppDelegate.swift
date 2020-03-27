import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var coordinator: Coordinator?
    let paymentsManager: StorePaymentsManager = .shared

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        configureInAppPurchases()
        Style.configureAppearance(using: window)
        configureCoordinator()
        clearTemporaryDirectory()

        return true
    }

    func applicationWillTerminate(_ application: UIApplication) {
        clearTemporaryDirectory()
        paymentsManager.stopObservingPayments()
    }

    private func configureCoordinator() {
        guard let navigationController = window?.rootViewController as? NavigationController else {
            fatalError("Wrong root view controller")            
        }

        coordinator = Coordinator(navigationController: navigationController)
        coordinator?.start()
    }

    private func configureInAppPurchases() {
        paymentsManager.purchasedProductsStore = UserDefaults.standard
        paymentsManager.startObservingPayments()
        paymentsManager.flushFinishedTransactions()
    }

    /// Clear any remaining temporary frames or live photo data exports.
    private func clearTemporaryDirectory() {
        try? FileManager.default.clearTemporaryDirectory()
    }
}
