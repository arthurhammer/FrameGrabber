import UIKit

final class LibraryButtonBar: UIView {
    
    struct Item {
        let image: UIImage?
        let action: UIAction
        let accessibilityLabel: String?
    }
    
    var buttonItems: [UIButton] {
        stackView.arrangedSubviews.compactMap { $0 as? UIButton }
    }
    
    var backgroundEffect: UIBlurEffect? = UIBlurEffect(style: .systemThickMaterial) {
        didSet { backgroundView.effect = backgroundEffect }
    }
        
    private let stackView = UIStackView()
    private let backgroundView = UIVisualEffectView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(frame: .zero)
        configureViews()
    }
    
    func configure(with items: [Item]) {
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        items.forEach { item in
            stackView.addArrangedSubview(button(for: item))
            stackView.addArrangedSubview(separator())
        }
        
        stackView.arrangedSubviews.last?.removeFromSuperview()  // Ditch last separator
    }
    
    private func configureViews() {
        layer.cornerRadius = 18
        layer.cornerCurve = .continuous
        clipsToBounds = true
                
        backgroundView.effect = backgroundEffect
        backgroundView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(backgroundView)
                
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fill
        
        addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }
    
    private func button(for item: Item) -> UIButton {
        let button = UIButton.libraryButtonBar()
        button.setImage(item.image, for: .normal)
        button.addAction(item.action, for: .primaryActionTriggered)
        button.accessibilityLabel = item.accessibilityLabel
        return button
    }
    
    private func separator() -> UIView {
        let separator = UIView()
        separator.backgroundColor = .label.withAlphaComponent(0.1)
        stackView.addArrangedSubview(separator)
        
        NSLayoutConstraint.activate([
            separator.widthAnchor.constraint(equalToConstant: 1),
            separator.heightAnchor.constraint(equalTo: stackView.heightAnchor, multiplier: 0.5),
        ])
        
        return separator
    }
}
