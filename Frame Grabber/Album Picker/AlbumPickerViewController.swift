import PhotoAlbums
import UIKit

protocol AlbumPickerViewControllerDelegate: class {
    /// The album is `nil` if the controller finished without picking an album.
    func picker(_ picker: AlbumPickerViewController, didFinishPicking album: AnyAlbum?)
}

/// A view controller to pick photo albums.
///
/// The controller manages its own internal navigation controller. It is intended to be presented
/// modally.
class AlbumPickerViewController: UIViewController {
    
    var delegate: AlbumPickerViewControllerDelegate?
    
    private let dataSource: AlbumsDataSource
    
    private lazy var childNavigationController = UINavigationController(rootViewController: self.listController)
    
    private lazy var listController: AlbumListViewController = {
        UIStoryboard(name: "Album Picker", bundle: nil).instantiateInitialViewController {
            AlbumListViewController(coder: $0, dataSource: self.dataSource, delegate: self)
        }!
    }()
    
    init(dataSource: AlbumsDataSource, delegate: AlbumPickerViewControllerDelegate? = nil) {
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
}

extension AlbumPickerViewController: AlbumListViewControllerDelegate {
    
    func controller(_ controller: AlbumListViewController, didSelectAlbum album: AnyAlbum) {
        dismiss(animated: true)
        delegate?.picker(self, didFinishPicking: album)
    }
    
    func controllerDidSelectDone(_ controller: AlbumListViewController) {
        dismiss(animated: true)
        delegate?.picker(self, didFinishPicking: nil)
    }
}
