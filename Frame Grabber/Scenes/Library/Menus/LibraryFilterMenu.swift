import UIKit

struct LibraryFilterMenu {

    enum Selection {
        case filter(PhotoLibraryFilter)
        case gridMode(LibraryGridMode)
    }

    @available(iOS 14, *)
    static func menu(
        with currentFilter: PhotoLibraryFilter,
        gridMode: LibraryGridMode,
        handler: @escaping (Selection) -> Void
    ) -> UIMenu {
        
        let filterActions = PhotoLibraryFilter.allCases.reversed().map { filter in
            UIAction(
                title: filter.title,
                image: filter.icon,
                state: (currentFilter == filter) ? .on : .off,
                handler: { _ in handler(.filter(filter)) }
            )
        }

        let gridAction = UIAction(
            title: gridMode.toggled.title,
            image: gridMode.toggled.icon,
            handler: { _ in handler(.gridMode(gridMode.toggled)) }
        )
        
        let filterMenu = UIMenu(title: "", options: .displayInline, children: filterActions)
        let gridMenu = UIMenu(title: "", options: .displayInline, children: [gridAction])

        return UIMenu(title: UserText.albumViewSettingsMenuTitle, children: [gridMenu, filterMenu])
    }

    @available(iOS, obsoleted: 14, message: "Use context menus")
    static func alertController(
        with currentFilter: PhotoLibraryFilter,
        gridMode: LibraryGridMode,
        handler: @escaping (Selection) -> Void
    ) -> UIAlertController {

        let controller = UIAlertController(
            title: UserText.albumViewSettingsMenuTitle,
            message: nil,
            preferredStyle: .actionSheet
        )

        let filterActions = PhotoLibraryFilter.allCases.map { filter -> UIAlertAction in
            let action = UIAlertAction(
                title: filter.title,
                style: .default,
                handler: { _ in handler(.filter(filter)) }
            )

            action.setValue(currentFilter == filter, forKey: "checked")
            return action
        }

        let gridAction = UIAlertAction(
            title: gridMode.toggled.title,
            style: .default,
            handler: { _ in handler(.gridMode(gridMode.toggled)) }
        )

        controller.addActions(filterActions + [gridAction, .cancel()])

        return controller
    }
    
    @available(iOS, obsoleted: 14, message: "Use context menus.")
    static func presentAsAlert(
        from presenter: UIViewController,
        currentFilter: PhotoLibraryFilter,
        gridMode: LibraryGridMode,
        barItem: UIBarButtonItem,
        selection: @escaping (Selection) -> Void
    ) {
        let alert = alertController(with: currentFilter, gridMode: gridMode, handler: selection)
        alert.popoverPresentationController?.barButtonItem = barItem
        presenter.present(alert, animated: true)
    }
}
