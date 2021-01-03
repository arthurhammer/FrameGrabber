import UIKit

struct AlbumViewSettingsMenu {

    enum Selection {
        case videosFilter(VideoTypesFilter)
        case gridMode(AlbumGridContentMode)
    }

    @available(iOS 14, *)
    static func menu(
        forCurrentFilter currentFilter: VideoTypesFilter,
        gridMode: AlbumGridContentMode,
        handler: @escaping (Selection) -> Void
    ) -> UIMenu {
        
        let filterActions = VideoTypesFilter.allCases.reversed().map { filter in
            UIAction(
                title: filter.title,
                image: filter.image,
                state: (currentFilter == filter) ? .on : .off,
                handler: { _ in handler(.videosFilter(filter)) }
            )
        }

        let gridAction = UIAction(
            title: gridMode.toggled.title,
            image: gridMode.toggled.image,
            handler: { _ in handler(.gridMode(gridMode.toggled)) }
        )
        
        let filterMenu = UIMenu(title: "", options: .displayInline, children: filterActions)
        let gridMenu = UIMenu(title: "", options: .displayInline, children: [gridAction])

        return UIMenu(title: UserText.albumViewSettingsMenuTitle, children: [gridMenu, filterMenu])
    }

    static func alertController(
        forCurrentFilter currentFilter: VideoTypesFilter,
        gridMode: AlbumGridContentMode,
        handler: @escaping (Selection) -> Void
    ) -> UIAlertController {

        let controller = UIAlertController(
            title: UserText.albumViewSettingsMenuTitle,
            message: nil,
            preferredStyle: .actionSheet
        )

        let filterActions = VideoTypesFilter.allCases.map { filter -> UIAlertAction in
            let action = UIAlertAction(
                title: filter.title,
                style: .default,
                handler: { _ in handler(.videosFilter(filter)) }
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
}
