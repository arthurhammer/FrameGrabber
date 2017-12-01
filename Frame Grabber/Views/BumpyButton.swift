import UIKit

class BumpyButton: UIButton {

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureViews()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configureViews()
    }

    private func configureViews() {
        addTarget(self, action: #selector(touchUpInside), for: .touchUpInside)
    }

    @objc private func touchUpInside() {
        bump(by: 1.1)
    }
}
