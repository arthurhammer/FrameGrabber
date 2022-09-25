import UIKit

extension UIViewController {
    
    /// Sets the controller's preferred content height to an expanded size. The width is not specified.
    ///
    /// This can be used to expand view controllers in popovers or other containers.
    public func updateExpandedPreferredContentSize() {
        let expandedHeight = view.systemLayoutSizeFitting(UIView.layoutFittingExpandedSize).height
        let expandedSize = CGSize(width: UIView.noIntrinsicMetric, height: expandedHeight)
        
        if preferredContentSize != expandedSize {
            preferredContentSize = expandedSize
        }
    }
    
    /// Configures the receiver to be presented in a sheet with a height matching the receiver's `preferredContentSize`.
    ///
    /// When the preferred content size of the receiver changes, update the sheet size using `invalidateSheetDetents()`.
    ///
    /// - Note: On iOS 15, uses a non-resizable `large` sheet detent.
    public func configureCompactSheetPresentation() {
        modalPresentationStyle = .formSheet
        sheetPresentationController?.preferredCornerRadius = 32
        sheetPresentationController?.prefersEdgeAttachedInCompactHeight = true
        sheetPresentationController?.widthFollowsPreferredContentSizeWhenEdgeAttached = false

        if #available(iOS 16.0, *) {
            sheetPresentationController?.detents = [.preferredContentSize(of: self)]
        } else {
            sheetPresentationController?.detents = [.large()]
        }
    }
    
    @available(iOS 16.0, *)
    public func invalidateSheetDetents(animated: Bool) {
        if animated {
            sheetPresentationController?.animateChanges {
                sheetPresentationController?.invalidateDetents()
            }
        } else {
            sheetPresentationController?.invalidateDetents()
        }
    }
}

// MARK: - Sheet Detents

extension UISheetPresentationController.Detent {
    
    /// Uses the given view controller's `preferredContentSize` to size the detent.
    ///
    /// When the preferred content size changes, update the sheet size using `UISheetPresentationController.invalidateDetents()`.
    @available(iOS 16.0, *)
    public static func preferredContentSize(
        of viewController: UIViewController,
        fallbackDetent: UISheetPresentationController.Detent = .medium()
    ) -> UISheetPresentationController.Detent {
        .custom(identifier: .preferredContentSize) { [weak viewController] context in
            let height = viewController?.preferredContentSize.height ?? 0
            let isValid = (height > 0) && (height != UIView.noIntrinsicMetric)
            return isValid ? height : fallbackDetent.fallbackHeight(in: context)
        }
    }
    
    @available(iOS 16.0, *)
    private func fallbackHeight(in context: UISheetPresentationControllerDetentResolutionContext) -> CGFloat {
        resolvedValue(in: context) ?? min(500, context.maximumDetentValue)
    }
}

extension UISheetPresentationController.Detent.Identifier {
    public static let preferredContentSize = Self(rawValue: "preferredContentSize")
}


// MARK: - Embedding View Controllers

extension UIViewController {

    /// Adds the given view controller as a child controller.
    ///
    /// Sets the child's view's frame and autoresizing mask to occupy the receiver's view fully.
    public func embed(_ childController: UIViewController) {
        guard !children.contains(childController) else { return }
        
        // It is generally ok to trigger a view load when embedding the child but this can
        // prematurely load the child's view (e.g. when it is hidden in a tab or navigation
        // controller). During development, we keep the assert to be mindful of this situation.
        assert(isViewLoaded, "Embedded a child before the view loaded.")
        
        addChild(childController)
        view.addSubview(childController.view)

        childController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        childController.view.frame = view.bounds

        childController.didMove(toParent: self)
    }
    
    /// Removes the given view controller as a child controller.
    public func unembed(_ childController: UIViewController) {
        guard childController.parent == self else { return }
        
        childController.willMove(toParent: nil)
        childController.view.removeFromSuperview()
        childController.removeFromParent()
    }
}

