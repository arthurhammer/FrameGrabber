import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        configureAppearance()
        
        window = UIWindow(frame: UIScreen.main.bounds)
        showInitialScreen()
        window?.makeKeyAndVisible()

        return true
    }

    private func configureAppearance() {
        UINavigationBar.appearance().barTintColor = .white
        UINavigationBar.appearance().tintColor = .accent
        UINavigationBar.appearance().shadowImage = UIImage()
    }

    func applicationWillResignActive(_ application: UIApplication) {}
    func applicationDidEnterBackground(_ application: UIApplication) {}
    func applicationWillEnterForeground(_ application: UIApplication) {}
    func applicationDidBecomeActive(_ application: UIApplication) {}
    func applicationWillTerminate(_ application: UIApplication) {}
}
