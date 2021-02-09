import UIKit

struct LimitedAuthorizationMenu {

    enum Selection: String {
        case selectPhotos
        case openSettings
    }
    
    static func menu(selection: @escaping (Selection) -> ()) -> UIMenu {
        UIMenu(title: UserText.limitedAuthorizationMenuTitle, children: [
            UIAction(
                title: UserText.limitedAuthorizationMenuSelectPhotosAction,
                image: UIImage(systemName: "photo.on.rectangle")
            ) { _ in
                selection(.selectPhotos)
            },
            UIAction(
                title: UserText.limitedAuthorizationMenuOpenSettingsAction,
                image: UIImage(systemName: "arrow.up.forward.app")
            ) { _ in
                selection(.openSettings)
            }
        ])
    }
}
