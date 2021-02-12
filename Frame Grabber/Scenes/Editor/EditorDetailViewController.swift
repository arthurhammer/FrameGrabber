import AVFoundation
import UIKit

/// Manages the presentation of the settings and metadata controllers in a paged view.
class EditorDetailViewController: UIViewController {
    
    // TODO: injection
    var video: AVAsset?
    var videoSource: VideoSource?
    
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
        return storyboard.instantiateViewController(withIdentifier: id) as! SettingsViewController
    }()
    
    private lazy var metadataController: MetadataViewController = {
        let storyboard = UIStoryboard(name: "Metadata", bundle: nil)
        let id = MetadataViewController.className
        let controller = storyboard.instantiateViewController(withIdentifier: id) as! MetadataViewController
        controller.viewModel = .init(video: video!, source: videoSource!)
        return controller
    }()
    
    private lazy var titleSegments: UISegmentedControl = {
        let control = UISegmentedControl(items: ["<Settings>", "<Metadata>"])
        control.addTarget(self, action: #selector(selectionChanged), for: .valueChanged)
        return control
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureViews()
    }
    
    @objc private func done() {
        dismiss(animated: true)
    }
     
    private func configureViews() {
        embed(pageController)
        setPage(at: 0, animated: false)

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
    }
    
    @objc private func selectionChanged(_ sender: UISegmentedControl) {
        setPage(at: sender.selectedSegmentIndex, animated: true)
    }
    
    // MARK: - Page Access
    
    private var currentPage: UIViewController? {
        pageController.viewControllers?.first
    }
    
    private var currentIndex: Int? {
        // Don't trigger lazy load of metadata if not needed.
        guard currentPage != nil else { return nil }
        return (currentPage == settingsController) ? 0 : 1
    }
    
    private func setPage(at index: Int, animated: Bool) {
        guard index != currentIndex else { return }
        
        // Don't trigger lazy load of metadata if not needed.
        let page = (index == 0) ? settingsController : metadataController

        pageController.setViewControllers(
            [page],
            direction: (index == 0) ? .reverse : .forward,
            animated: animated
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
