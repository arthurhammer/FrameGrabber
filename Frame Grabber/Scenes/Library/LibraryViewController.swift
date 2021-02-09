import Combine
import Photos
import PhotosUI
import UIKit

protocol LibraryViewControllerDelegate: class {
    func controllerDidSelectAlbumPicker(_ controller: LibraryViewController)
    func controllerDidSelectFilePicker(_ controller: LibraryViewController)
    func controllerDidSelectCamera(_ controller: LibraryViewController)
}

class LibraryViewController: UIViewController {
    
    typealias Delegate = LibraryViewControllerDelegate & LibraryGridViewControllerDelegate
    
    weak var delegate: Delegate? {
        didSet {
            // set grid delegate
        }
    }
            
    override var title: String? {
        didSet { titleButton.setTitle(title, for: .normal, animated: false) }
    }
    
    var album: PHAssetCollection? {
        nil
//        dataSource.album
    }

    /// The asset that is the the source/target for the zoom push/pop transition, typically the last
    /// selected asset.
    var transitionAsset: PHAsset? {
        didSet {
//            select(asset: transitionAsset, animated: false) 
        }
    }
    
    // view model for settings?
    var filter: PhotoLibraryFilter = .videoAndLivePhoto
    // forward
    var gridMode: LibraryGridMode = .square
    
    var isAuthorizationLimited = false //

    @IBOutlet private var titleButton: UIButton!
    @IBOutlet private var filterButton: LibraryFilterButton!
    
    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configureViews()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateNavigationBar()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        updateContentInsetForViewSettingsButton()
    }
    
    // MARK: - Setting Albums
    
    func setAlbum(_ album: PHAssetCollection) {
//        dataSource.setAlbum(album)
    }

    // MARK: - Actions

    @objc private func showAlbumPicker() {
        delegate?.controllerDidSelectAlbumPicker(self)
    }
    
    @IBAction private func showFilePicker() {
        delegate?.controllerDidSelectFilePicker(self)
    }
    
    @IBAction private func showCamera() {
        delegate?.controllerDidSelectCamera(self)
    }
}

private extension LibraryViewController {
    
    // MARK: Configuring

    func configureViews() {
        navigationItem.titleView = UIView()
        titleButton.configureDynamicTypeLabel()
        titleButton.configureTrailingAlignedImage()
        
        if #available(iOS 14, *) {
            filterButton.showsMenuAsPrimaryAction = true
        } else {
            let action = #selector(showFilterMenuAsSheet)
            filterButton.addTarget(self, action: action, for: .touchUpInside)
        }
        
        filterButton.add(to: view)
        updateViews()
    }

    func updateViews() {
        guard isViewLoaded else { return }
        
        if #available(iOS 14.0, *),
           isAuthorizationLimited {

            title = UserText.albumLimitedAuthorizationTitle
            titleButton.showsMenuAsPrimaryAction = true
            
            titleButton.menu = LimitedAuthorizationMenu.menu { [weak self] selection in
                self?.handleLimitedAuthorizationMenuSelection(selection)
            }
        } else {
            // todo: title
//            title = dataSource.album?.localizedTitle ?? UserText.albumFallbackTitle
            titleButton.addTarget(self, action: #selector(showAlbumPicker), for: .touchUpInside)
        }

        updateFilterButton()
        updateNavigationBar()
    }
    
    func updateNavigationBar() {
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.layer.shadowOpacity = 0

        if #available(iOS 14.0, *) {
            navigationItem.backButtonDisplayMode = .minimal
        }
    }

    @available(iOS 14, *)
    func handleLimitedAuthorizationMenuSelection(_ selection: LimitedAuthorizationMenu.Selection) {
        switch selection {
        
        case .selectPhotos:
//            dataSource.photoLibrary.presentLimitedLibraryPicker(from: self)
            break
            
        case .openSettings:
            UIApplication.shared.openSettings()
        }
    }

    // MARK: Filter Button

    func updateFilterButton() {
        filterButton.setTitle(filter.title, for: .normal, animated: false)
        
        if #available(iOS 14, *) {
            filterButton.menu = LibraryFilterMenu.menu(
                with: filter,
                gridMode: gridMode,
                handler: { [weak self] selection in
                    DispatchQueue.main.async {
                        self?.handleViewSettingsMenuSelection(selection)
                    }
                }
            )
        }
    }

    @objc func showFilterMenuAsSheet() {
        let controller = LibraryFilterMenu.alertController(
            with: filter,
            gridMode: gridMode,
            handler: { [weak self] selection in
                DispatchQueue.main.async {
                    self?.handleViewSettingsMenuSelection(selection)
                }
            }
        )

        controller.popoverPresentationController?.sourceView = filterButton
        presentAlert(controller)
    }

    func handleViewSettingsMenuSelection(_ selection: LibraryFilterMenu.Selection) {
        UISelectionFeedbackGenerator().selectionChanged()

        switch selection {
        
        case .filter(let filter):
            self.filter = filter
            
        case .gridMode(let mode):
            gridMode = mode
            // Set mode on grid vs
        }

        updateFilterButton()
    }

    func updateContentInsetForViewSettingsButton() {
        let topMargin: CGFloat = 8
        let bottomInset = filterButton.bounds.height + topMargin

        // Update
//        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: bottomInset, right: 0)
//        collectionView.verticalScrollIndicatorInsets = collectionView.contentInset
    }
}
