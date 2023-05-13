import UIKit
import Utility

final class LibraryEmptyView: UIView {
    
    private(set) lazy var titleLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = .preferredFont(forTextStyle: .title3, weight: .semibold)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        return label
    }()
    
    private(set) lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.tintColor = .systemGray3
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(systemName: "photo.on.rectangle.angled")

        NSLayoutConstraint.activate([
            imageView.heightAnchor.constraint(equalToConstant: 60),
            imageView.widthAnchor.constraint(equalTo: imageView.heightAnchor)
        ])
        
        return imageView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureViews()
    }
    
    // MARK: Configuring

    private func configureViews() {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = UIStackView.spacingUseSystem
        stack.distribution = .fill
        stack.alignment = .center
        
        stack.addArrangedSubview(imageView)
        stack.addArrangedSubview(titleLabel)
        addSubview(stack)
        
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: readableContentGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: readableContentGuide.trailingAnchor),
            stack.centerYAnchor.constraint(equalTo: safeAreaLayoutGuide.centerYAnchor),
            stack.topAnchor.constraint(greaterThanOrEqualTo: safeAreaLayoutGuide.topAnchor, constant: 16),
            safeAreaLayoutGuide.bottomAnchor.constraint(greaterThanOrEqualTo: stack.bottomAnchor, constant: 16)
        ])
    }
}
