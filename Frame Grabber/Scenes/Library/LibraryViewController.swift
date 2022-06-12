import Combine
import Photos
import PhotosUI
import UIKit

protocol LibraryViewControllerDelegate: AnyObject {
    func controller(_ controller: LibraryViewController, didSelectAsset asset: PHAsset, previewImage: UIImage?)
    func controllerDidSelectAlbumPicker(_ controller: LibraryViewController)
    func controllerDidSelectFilePicker(_ controller: LibraryViewController)
    func controllerDidSelectCamera(_ controller: LibraryViewController)
    func controllerDidSelectAddMoreVideos(_ controller: LibraryViewController)
    func controllerDidSelectSettings(_ controller: LibraryViewController)
    func controllerDidSelectAbout(_ controller: LibraryViewController)
}

final class LibraryViewController: UIViewController {
    
    typealias Delegate = LibraryViewControllerDelegate
    
    weak var delegate: Delegate?
    
    let dataSource = LibraryDataSource()
    
    private(set) var gridController: LibraryGridViewController?
            
    override var title: String? {
        didSet { titleButton.setTitle(title, for: .normal, animated: false) }
    }
    
    /// The asset that is the source/target for the zoom push/pop transition.
    ///
    /// The asset must be set explicitly, the controller does not set it automatically such as when
    /// a cell is selected.
    var zoomTransitionAsset: PHAsset?
    
    @IBOutlet private var filterBarItem: UIBarButtonItem!
    @IBOutlet private var toolbar: LibraryToolbar!
    private let titleButton = UIButton.libraryTitle()
    private var bindings = Set<AnyCancellable>()
    
    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configureViews()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateNavigationBar()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateGridSafeArea()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard previousTraitCollection?.verticalSizeClass != traitCollection.verticalSizeClass else { return }
        updateTitleButton()
    }
    
    @IBSegueAction private func makeGridController(_ coder: NSCoder) -> LibraryGridViewController? {
        gridController = LibraryGridViewController(dataSource: dataSource, coder: coder)
        gridController?.delegate = self
        return gridController
    }

    // MARK: - Actions

    private func showAlbumPicker() {
        delegate?.controllerDidSelectAlbumPicker(self)
    }
    
    @IBAction private func showFilePicker() {
        delegate?.controllerDidSelectFilePicker(self)
    }
    
    @IBAction private func showCamera() {
        delegate?.controllerDidSelectCamera(self)
    }
    
    @IBAction func showAbout() {
        delegate?.controllerDidSelectAbout(self)
    }
    
    // MARK: Configuring

    private func configureViews() {
        configureTitleButton()
        configureBindings()
        updateNavigationBar()
    }
    
    private func configureTitleButton() {
        navigationItem.titleView = UIView()  // Hide default title label
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: titleButton)
        updateTitleButton()
    }
    
    private func updateTitleButton() {
        if dataSource.isAuthorizationLimited {
            title = Localized.libraryLimitedTitle
            titleButton.showsMenuAsPrimaryAction = true
            titleButton.menu = LibraryMenu.Limited.menu { [weak self] selection in
                self?.handleLimitedMenuSelection(selection)
            }
        } else {
            title = dataSource.album?.localizedTitle ?? Localized.libraryDefaultTitle
            titleButton.showsMenuAsPrimaryAction = false
            titleButton.addAction(.init { [weak self] _ in
                self?.showAlbumPicker()
            }, for: .primaryActionTriggered)
        }
        
        let isCompact = traitCollection.verticalSizeClass == .compact
        titleButton.titleLabel?.font = UIButton.libraryTitleFont(isCompact: isCompact)
    }

    private func configureBindings() {
        // React to initial authorization if status is `notDetermined`.
        dataSource.$isAuthorizationLimited
            .combineLatest(dataSource.$album)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateTitleButton()
            }
            .store(in: &bindings)
        
        dataSource.$filter
            .combineLatest(dataSource.$gridMode)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateFilterMenu()
            }.store(in: &bindings)
    }
    
    private func updateNavigationBar() {
        let standardAppearance = UINavigationBarAppearance()
        standardAppearance.shadowColor = nil
        navigationItem.standardAppearance = standardAppearance
        navigationController?.navigationBar.layer.shadowOpacity = 0  // Reset the custom editor shadow.
        navigationItem.backButtonDisplayMode = .minimal
    }
    
    private func updateGridSafeArea() {
        let spacing: CGFloat = 8
        let toolbarTop = view.safeAreaLayoutGuide.layoutFrame.maxY - toolbar.frame.minY
        gridController?.additionalSafeAreaInsets.bottom = toolbarTop + spacing
    }

    // MARK: Menus

    private func updateFilterMenu() {
        let menu = LibraryMenu.Filter.menu(
            with: dataSource.filter,
            gridMode: dataSource.gridMode,
            handler: { [weak self] selection in
                self?.handleFilterMenuSelection(selection)
            }
        )
        
        filterBarItem.menu = menu
        filterBarItem.image = menu.image
    }

    private func handleFilterMenuSelection(_ selection: LibraryMenu.Filter.Selection) {
        switch selection {
        case .filter(let filter):
            dataSource.filter = filter
        case .gridMode(let mode):
            dataSource.gridMode = mode
        }
    }
    
    private func handleLimitedMenuSelection(_ selection: LibraryMenu.Limited.Selection) {
        switch selection {
        case .addMorePhotos:
            delegate?.controllerDidSelectAddMoreVideos(self)
        case .showSettings:
            delegate?.controllerDidSelectSettings(self)
        }
    }
}

// MARK: - LibraryGridViewControllerDelegate

extension LibraryViewController: LibraryGridViewControllerDelegate {
    func controller(_ controller: LibraryGridViewController, didSelectAsset asset: PHAsset, previewImage: UIImage?) {
        delegate?.controller(self, didSelectAsset: asset, previewImage: previewImage)
    }
}
