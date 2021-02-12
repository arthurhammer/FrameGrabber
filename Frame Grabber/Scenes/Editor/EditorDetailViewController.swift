import AVFoundation
import UIKit

typealias EditorDetailViewControllerDelegate = SettingsViewControllerDelegate

/// Manages the presentation of the settings and metadata controllers in a paged view.
class EditorDetailViewController: UIViewController {
    
    weak var delegate: EditorDetailViewControllerDelegate? {
        didSet { settingsController.delegate = delegate }
    }
    
    let video: AVAsset
    let videoSource: VideoSource
    
    init(video: AVAsset, source: VideoSource, delegate: EditorDetailViewControllerDelegate? = nil) {
        self.video = video
        self.videoSource = source
        self.delegate = delegate
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private lazy var pageController: UIPageViewController = {
        let controller = UIPageViewController(
            transitionStyle: .scroll,
            navigationOrientation: .horizontal,
            options: nil
        )
        controller.delegate = self
        controller.dataSource = self
        return controller
    }()
    
    private lazy var settingsController: SettingsViewController = {
        let storyboard = UIStoryboard(name: "Settings", bundle: nil)
        let id = SettingsViewController.className
        let controller = storyboard.instantiateViewController(withIdentifier: id) as! SettingsViewController
        controller.delegate = delegate
        controller.tableView.backgroundColor = .clear
        return controller
    }()
    
    private lazy var metadataController: MetadataViewController = {
        let storyboard = UIStoryboard(name: "Metadata", bundle: nil)
        let id = MetadataViewController.className
        let controller = storyboard.instantiateViewController(withIdentifier: id) as! MetadataViewController
        controller.viewModel = .init(video: video, source: videoSource)
        controller.tableView.backgroundColor = .clear
        return controller
    }()
    
    private lazy var titleSegments: UISegmentedControl = {
        let control = UISegmentedControl(items: [
            UserText.editorDetailSettingsSectionTitle,
            UserText.editorDetailMetadataSectionTitle
        ])
        control.addTarget(self, action: #selector(selectionChanged), for: .valueChanged)
        return control
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureViews()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateContentSize()
    }
    
    private func updateContentSize() {
        DispatchQueue.main.async {
            guard let page = self.currentPage,
                  self.preferredContentSize != page.preferredContentSize else { return }

            // In popovers, reducing the content size does not seem to shrink the popover unless it
            // is set on the containing navigation controller.
            let container = self.navigationController ?? self
            container.preferredContentSize = page.preferredContentSize
        }
    }
    
    @objc private func done() {
        dismiss(animated: true)
    }
     
    private func configureViews() {
        embed(pageController)
        setPage(at: 0, animated: false)
        
        let backgroundView = UIVisualEffectView(effect: UIBlurEffect(style: .systemThickMaterial))
        backgroundView.frame = view.bounds
        backgroundView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.insertSubview(backgroundView, at: 0)
        view.backgroundColor = .clear

        navigationItem.largeTitleDisplayMode = .never
        navigationItem.titleView = titleSegments
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(done)
        )
        
        updateViews()
    }
    
    private func updateViews() {
        title = currentPage?.navigationItem.title
        titleSegments.selectedSegmentIndex = currentIndex ?? 0
        updateContentSize()
    }
    
    @objc private func selectionChanged(_ sender: UISegmentedControl) {
        setPage(at: sender.selectedSegmentIndex, animated: true)
    }
    
    // MARK: - Page Access
    
    private var currentPage: UIViewController? {
        pageController.viewControllers?.first
    }
    
    private var currentIndex: Int? {
        // Don't trigger lazy load of metadata.
        guard currentPage != nil else { return nil }
        return (currentPage == settingsController) ? 0 : 1
    }
    
    private func setPage(at index: Int, animated: Bool) {
        guard index != currentIndex else { return }
        
        // Don't trigger lazy load of metadata.
        let page = (index == 0) ? settingsController : metadataController

        pageController.setViewControllers(
            [page],
            direction: (index == 0) ? .reverse : .forward,
            animated: animated,
            completion: { _ in
                self.updateContentSize()
            }
        )
    }
}

// MARK: - UIPageViewControllerDataSource, UIPageViewControllerDelegate

extension EditorDetailViewController: UIPageViewControllerDelegate, UIPageViewControllerDataSource {
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        (viewController == settingsController) ? nil : settingsController
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        (viewController == settingsController) ? metadataController : nil
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        updateViews()
    }
}
