import UIKit

protocol NavigationBarHiddenPreferring {
    var prefersNavigationBarHidden: Bool { get }
}

class NavigationController: UINavigationController {

    override var viewControllers: [UIViewController] {
        didSet { updateNavigationBar(animated: false) }
    }

    override func setViewControllers(_ viewControllers: [UIViewController], animated: Bool) {
        super.setViewControllers(viewControllers, animated: animated)
        updateNavigationBar(animated: false)
    }

    override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        super.pushViewController(viewController, animated: animated)
        updateNavigationBar(animated: false)
    }

    override func popViewController(animated: Bool) -> UIViewController? {
        let popped = super.popViewController(animated: animated)
        updateNavigationBar(animated: false)
        return popped
    }

    private func updateNavigationBar(animated: Bool) {
        guard let prefersHidden = (topViewController as? NavigationBarHiddenPreferring)?.prefersNavigationBarHidden else { return }
        setNavigationBarHidden(prefersHidden, animated: animated)
    }
}
