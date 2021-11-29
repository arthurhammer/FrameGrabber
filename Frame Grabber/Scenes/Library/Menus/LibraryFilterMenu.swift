import UIKit

struct LibraryFilterMenu {

    enum Selection {
        case filter(PhotoLibraryFilter)
        case gridMode(LibraryGridMode)
    }

    static func menu(
        with currentFilter: PhotoLibraryFilter,
        gridMode: LibraryGridMode,
        handler: @escaping (Selection) -> Void
    ) -> UIMenu {
        
        let filterActions = PhotoLibraryFilter.allCases.map { filter in
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
        
        let filterMenu = UIMenu(options: .displayInline, children: filterActions)
        let gridMenu = UIMenu(options: .displayInline, children: [gridAction])

        return UIMenu(title: UserText.albumViewSettingsMenuTitle, children: [filterMenu, gridMenu])
    }
}
