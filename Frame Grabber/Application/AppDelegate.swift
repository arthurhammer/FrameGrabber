import InAppPurchase
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var coordinator: Coordinator?
    let paymentsManager: StorePaymentsManager = .shared
    let fileManager = AppFileManager()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        configureInAppPurchases()
        Style.configureAppearance(for: window)
        configureCoordinator()
        
        if launchOptions?[.url] == nil {
            try? fileManager.clearTemporaryDirectories()
        }

        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        let openInPlace = options[.openInPlace] as? Bool == true
        let _url = try? fileManager.importVideo(at: url, asCopy: true, deletingSource: !openInPlace)
        
        guard let url = _url,
              let coordinator = coordinator else { return false }
        
        return coordinator.open(videoUrl: url)
    }

    func applicationWillTerminate(_ application: UIApplication) {
        try? fileManager.clearTemporaryDirectories()
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
}
