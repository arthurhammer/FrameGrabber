import Combine
import Photos
import PhotosUI
import UIKit

protocol LibraryViewControllerDelegate: AnyObject {
    func controllerDidSelectAlbumPicker(_ controller: LibraryViewController)
    func controllerDidSelectFilePicker(_ controller: LibraryViewController)
    func controllerDidSelectCamera(_ controller: LibraryViewController)
    func controllerDidSelectAddMoreVideos(_ controller: LibraryViewController)
    func controllerDidSelectOpenSettings(_ controller: LibraryViewController)
}

class LibraryViewController: UIViewController {
    
    typealias Delegate = LibraryViewControllerDelegate & LibraryGridViewControllerDelegate
    
    weak var delegate: Delegate? {
        didSet { gridController?.delegate = delegate }
    }
    
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
    
    @IBOutlet private var titleButton: UIButton!
    @IBOutlet private var filterBarItem: UIBarButtonItem!
    @IBOutlet private var toolbar: LibraryToolbar!
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
    
    @IBSegueAction private func makeGridController(_ coder: NSCoder) -> LibraryGridViewController? {
        gridController = LibraryGridViewController(dataSource: dataSource, coder: coder)
        gridController?.delegate = delegate
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
    
    // MARK: Configuring

    private func configureViews() {
        configureTitleButton()
        configureBindings()
        updateNavigationBar()
    }
    
    private func configureTitleButton() {
        navigationItem.titleView = UIView()
        titleButton.configureDynamicTypeLabel()
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
        UISelectionFeedbackGenerator().selectionChanged()

        switch selection {
        case .addMorePhotos:
            delegate?.controllerDidSelectAddMoreVideos(self)
        case .showSettings:
            delegate?.controllerDidSelectOpenSettings(self)
        }
    }
}
