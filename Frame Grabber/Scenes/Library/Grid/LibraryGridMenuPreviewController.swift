import Combine
import Photos
import UIKit

class LibraryGridMenuPreviewController: UIViewController {
    
    let asset: PHAsset
    
    private let initialImage: UIImage?
    private let minimumSize: CGSize
    private let imageManager: PHImageManager
    private var request: Cancellable?
    
    private lazy var imageView: UIImageView = {
        let imageView = UIImageView(image: initialImage)
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = .secondarySystemFill
        imageView.clipsToBounds = true
        return imageView
    }()
    
    private var targetSize: CGSize {
        let assetSize = asset.dimensions

        if (assetSize.width < minimumSize.width) || (assetSize.height < minimumSize.height) {
            return assetSize.aspectFilling(minimumSize)
        }
        
        return assetSize
    }
    
    init(
        asset: PHAsset,
        initialImage: UIImage?,
        minimumSize: CGSize = CGSize(width: 200, height: 200),
        imageManager: PHImageManager = .default()
    ) {
        self.asset = asset
        self.initialImage = initialImage
        self.minimumSize = minimumSize
        self.imageManager = imageManager
        
        super.init(nibName: nil, bundle: nil)
        
        loadImage()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureViews()
    }
    
    private func configureViews() {
        view = imageView
        view.bounds.size = targetSize
        preferredContentSize = targetSize
    }
    
    private func loadImage() {
        let options = PHImageManager.ImageOptions(
            size: targetSize.scaledToScreen,
            mode: .aspectFill,
            requestOptions: .default()
        )
        
        request = imageManager.requestImage(for: asset, options: options) { [weak self] image, _ in
            guard let image else { return }
            
            self?.imageView.image = image
        }
    }
}
