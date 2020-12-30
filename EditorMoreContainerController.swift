import UIKit

// Save latest controller

class EditorMoreContainerController: UIViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    
    
    @IBOutlet private var segmentedControl: UISegmentedControl!
    private var pageViewController: UIPageViewController!
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? UIPageViewController {
            pageViewController = destination
            pageViewController.delegate = self
            pageViewController.dataSource = self
            
            pageViewController.setViewControllers([UIStoryboard(name: "ExportSettings", bundle: nil).instantiateInitialViewController()!], direction: .forward, animated: false, completion: nil)
            
            segmentedControl.selectedSegmentIndex = (pageViewController.viewControllers?.first is ExportSettingsViewController) ? 0 : 1

        }
    }
    
    
    @IBAction private func done() {
        dismiss(animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.largeTitleDisplayMode = .always
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
//            self.pageViewController.navigationItem.title = "Test"
//            if #available(iOS 14.0, *) {
//                self.pageViewController.navigationItem.rightBarButtonItem = UIBarButtonItem(systemItem: .done)
//            } else {
//                // Fallback on earlier versions
//            }
//
//            self.navigationController?.setViewControllers([self.pageViewController], animated: false)
        })
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        
        return (pageViewController.viewControllers?.first is MetadataViewController) ? UIStoryboard(name: "ExportSettings", bundle: nil).instantiateInitialViewController() : nil
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        
        return (pageViewController.viewControllers?.first is MetadataViewController) ? nil : UIStoryboard(name: "Metadata", bundle: nil).instantiateInitialViewController()
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        
        title = pageViewController.viewControllers?.first?.title
        
        segmentedControl.selectedSegmentIndex = (pageViewController.viewControllers?.first is ExportSettingsViewController) ? 0 : 1
    }
    
}
