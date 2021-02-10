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

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        updateGridSafeArea()
    }
    
    @IBSegueAction private func makeGridController(_ coder: NSCoder) -> LibraryGridViewController? {
        gridController = LibraryGridViewController(dataSource: dataSource, coder: coder)
        gridController?.delegate = delegate
        return gridController
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
    
    // MARK: Configuring

    private func configureViews() {
        navigationItem.titleView = UIView()
        titleButton.configureDynamicTypeLabel()
        titleButton.configureTrailingAlignedImage()
        
        if #available(iOS 14, *) {
            toolbar.importButton.showsMenuAsPrimaryAction = true
        } else {
            let action = #selector(showFilterMenuAsSheet)
            toolbar.importButton.addTarget(self, action: action, for: .touchUpInside)
        }
        
        configureBindings()
        updateViews()
    }

    private func updateViews() {
        updateTitle()
        updateFilterButton()
        updateNavigationBar()
    }
    
    private func updateTitle() {
        if dataSource.isAuthorizationLimited,
           #available(iOS 14.0, *) {
            
            title = UserText.albumLimitedAuthorizationTitle
            titleButton.showsMenuAsPrimaryAction = true
            titleButton.menu = LimitedAuthorizationMenu.menu { [weak self] selection in
                self?.handleLimitedAuthorizationMenuSelection(selection)
            }
        } else {
            title = dataSource.album?.localizedTitle ?? UserText.libraryDefaultTitle
            titleButton.addTarget(self, action: #selector(showAlbumPicker), for: .touchUpInside)
        }
    }
    
    private func configureBindings() {
        dataSource.$album
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateTitle()
            }.store(in: &bindings)
    }
    
    private func updateNavigationBar() {
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.layer.shadowOpacity = 0

        if #available(iOS 14.0, *) {
            navigationItem.backButtonDisplayMode = .minimal
        }
    }
    
    private func updateGridSafeArea() {
        let spacing: CGFloat = 8
        let toolbarTop = view.safeAreaLayoutGuide.layoutFrame.maxY - toolbar.frame.minY
        gridController?.additionalSafeAreaInsets.bottom = toolbarTop + spacing
    }

    // MARK: Handling Menus

    private func updateFilterButton() {
        if #available(iOS 14, *) {
            filterBarItem.menu = LibraryFilterMenu.menu(
                with: dataSource.filter,
                gridMode: dataSource.gridMode,
                handler: { [weak self] selection in
                    DispatchQueue.main.async {
                        self?.handleFilterMenuSelection(selection)
                    }
                }
            )
        }
    }

    @available(iOS, obsoleted: 14, message: "Use context menus")
    @objc private  func showFilterMenuAsSheet() {
        let controller = LibraryFilterMenu.alertController(
            with: dataSource.filter,
            gridMode: dataSource.gridMode,
            handler: { [weak self] selection in
                DispatchQueue.main.async {
                    self?.handleFilterMenuSelection(selection)
                }
            }
        )

        controller.popoverPresentationController?.barButtonItem = filterBarItem
        presentAlert(controller)
    }

    private func handleFilterMenuSelection(_ selection: LibraryFilterMenu.Selection) {
        UISelectionFeedbackGenerator().selectionChanged()

        switch selection {
        case .filter(let filter):
            dataSource.filter = filter
        case .gridMode(let mode):
            dataSource.gridMode = mode
        }

        updateFilterButton()
    }
    
    @available(iOS 14, *)
    private func handleLimitedAuthorizationMenuSelection(_ selection: LimitedAuthorizationMenu.Selection) {
        switch selection {
        
        case .selectPhotos:
            dataSource.photoLibrary.presentLimitedLibraryPicker(from: self)
            
        case .openSettings:
            UIApplication.shared.openSettings()
        }
    }
}
