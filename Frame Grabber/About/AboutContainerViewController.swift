import UIKit

class AboutContainerViewController: UIViewController {

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        transitionCoordinator?.animate(alongsideTransition: { [weak self] _ in
            self?.styleNavigationBar()
        }, completion: { [weak self] _ in
            self?.styleNavigationBar()
        })
    }

    @IBAction private func done() {
        dismiss(animated: true)
    }

    private func styleNavigationBar() {
        let bar = navigationController?.navigationBar
        bar?.tintColor = nil
        bar?.shadowImage = nil
        bar?.setBackgroundImage(nil, for: .default)
    }
}
