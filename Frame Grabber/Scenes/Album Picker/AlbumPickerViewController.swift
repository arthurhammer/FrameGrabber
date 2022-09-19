import PhotoAlbums
import UIKit

@MainActor protocol AlbumPickerViewControllerDelegate: AnyObject {
    
    /// Tells the delegate the user finished picking an album.
    ///
    /// - Parameters:
    ///   - album: The picked album. Is `nil` if the controller finished without picking an album.
    func picker(_ picker: AlbumPickerViewController, didFinishPicking album: Album?)
}

/// A view controller to pick photo albums from the user's photo library.
///
/// The controller manages its own internal navigation controller. It is intended to be presented
/// modally.
final class AlbumPickerViewController: UIViewController {
    
    weak var delegate: AlbumPickerViewControllerDelegate?
    
    private let dataSource: AlbumPickerDataSource
    
    private lazy var childNavigationController = UINavigationController(
        rootViewController: self.listController
    )
    
    private lazy var listController: AlbumListViewController = makeListController()
    
    private static let storyboard = "Album Picker"
    
    /// - Parameters:
    ///   - dataSource: The data source providing photo albums. You can use the default
    ///    `AlbumsDataSource` implementation. It allows configuring to fetch the exact types of
    ///    albums and assets you want. Alternatively, you can provide a custom data source
    ///    conforming to `AlbumPickerDataSource`.
    ///   - delegate: The controller's delegate.
    init(
        dataSource: AlbumPickerDataSource = AlbumsDataSource(),
        delegate: AlbumPickerViewControllerDelegate? = nil
    ) {
        self.dataSource = dataSource
        self.delegate = delegate

        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("Storyboard instantiation not supported.")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        embed(childNavigationController)
        childNavigationController.navigationBar.prefersLargeTitles = true
    }
    
    private func makeListController() -> AlbumListViewController {
        let storyboard = UIStoryboard(name: AlbumPickerViewController.storyboard, bundle: nil)
        
        let initial = storyboard.instantiateInitialViewController {
            AlbumListViewController(coder: $0, dataSource: self.dataSource, delegate: self)
        }
        
        guard let controller = initial else { fatalError("Wrong storyboard name or configuration.") }
        
        return controller
    }
}

// MARK: - AlbumListViewControllerDelegate

extension AlbumPickerViewController: AlbumListViewControllerDelegate {
    
    func controller(_ controller: AlbumListViewController, didSelectAlbum album: Album) {
        dismiss(animated: true)
        delegate?.picker(self, didFinishPicking: album)
    }
    
    func controllerDidSelectDone(_ controller: AlbumListViewController) {
        dismiss(animated: true)
        delegate?.picker(self, didFinishPicking: nil)
    }
}
