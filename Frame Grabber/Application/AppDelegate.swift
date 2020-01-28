import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var coordinator: Coordinator?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        try? FrameExporter.clearTemporaryDirectory()

        Style.configureAppearance(using: window)

        coordinator = Coordinator(window: window)
        coordinator?.start()

        return true
    }

    func applicationWillTerminate(_ application: UIApplication) {
        try? FrameExporter.clearTemporaryDirectory()
    }
}
