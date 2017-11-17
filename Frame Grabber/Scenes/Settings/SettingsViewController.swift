import UIKit

class SettingsViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        configureViews()
    }

    @IBAction func done() {
        dismiss(animated: true)
    }

    private func configureViews() {
        view.backgroundColor = .mainBackground
    }
}
