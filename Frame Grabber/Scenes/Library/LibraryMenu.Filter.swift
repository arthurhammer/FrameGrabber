import UIKit

struct LibraryMenu {}

extension LibraryMenu {
    struct Filter {
        
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
                    image: filter.menuIcon,
                    state: (currentFilter == filter) ? .on : .off,
                    handler: { _ in
                        UISelectionFeedbackGenerator().selectionChanged()
                        handler(.filter(filter))
                    }
                )
            }

            let gridAction = UIAction(
                title: gridMode.toggled.title,
                image: gridMode.toggled.icon,
                handler: { _ in
                    UISelectionFeedbackGenerator().selectionChanged()
                    handler(.gridMode(gridMode.toggled))
                }
            )
            
            let filterMenu = UIMenu(options: .displayInline, children: filterActions)
            let gridMenu = UIMenu(options: .displayInline, children: [gridAction])
            
            return UIMenu(image: currentFilter.buttonIcon, children: [filterMenu, gridMenu])
        }
    }
}

// MARK: - Util

extension PhotoLibraryFilter {
    
    fileprivate var menuIcon: UIImage? {
        switch self {
        case .videoAndLivePhoto:
            return UIImage(systemName: "photo.on.rectangle.angled")
        case .video:
            return  UIImage(systemName: "video")
        case .livePhoto:
            return  UIImage(systemName: "livephoto")
        }
    }
    
    fileprivate var buttonIcon: UIImage? {
        switch self {
        case .videoAndLivePhoto:
            return UIImage(systemName: "line.horizontal.3.decrease.circle")
        case .video, .livePhoto:
            return  UIImage(systemName: "line.horizontal.3.decrease.circle.fill")
        }
    }
}
