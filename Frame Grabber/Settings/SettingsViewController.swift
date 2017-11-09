import UIKit

class SettingsViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        configureViews()
    }

    @IBAction func done() {
        dismiss(animated: true)
    }
}

private extension SettingsViewController {

    func configureViews() {
        view.backgroundColor = .mainBackgroundColor
        navigationItem.rightBarButtonItem?.tintColor = .accentColor
    }
}
