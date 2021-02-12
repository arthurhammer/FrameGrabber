import ThumbnailSlider
import UIKit

struct EditorSpeedMenu {
    
    enum Selection: Float, CaseIterable {
        case normal = 1
        case half = 0.5
        case quarter = 0.25
        case fine = 0.1
        case veryFine = 0.01
        
        var title: String {
            switch self {
            case .normal: return UserText.speedMenuNormalSpeedAction
            case .half: return UserText.speedMenuHalfSpeedAction
            case .quarter: return UserText.speedMenuQuarterSpeedAction
            case .fine: return UserText.speedMenuFineSpeedAction
            case .veryFine: return UserText.speedMenuVeryFineSpeedAction
            }
        }
        
        var menuIcon: UIImage? {
            switch self {
            case .normal: return nil
            default: return buttonIcon?.applyingSymbolConfiguration(.init(scale: .large))
            }
        }
        
        var buttonIcon: UIImage? {
            switch self {
            case .normal: return UIImage(systemName: "speedometer")
            case .half: return UIImage(systemName: "50.circle")
            case .quarter: return UIImage(systemName: "25.circle")
            case .fine: return UIImage(systemName: "10.circle")
            case .veryFine: return UIImage(systemName: "01.circle")
            }
        }
        
        var scrubbingSpeed: ScrubbingThumbnailSlider.Speed {
            .init(speed: rawValue, verticalDistance: 0)
        }
        
        init(_ scrubbingSpeed: ScrubbingThumbnailSlider.Speed) {
            self = Selection(scrubbingSpeed.speed) ?? .normal
        }
    }

    static var defaultSpeed: Selection {
        Selection.allCases.first!
    }

    @available(iOS 14, *)
    static func menu(
        with current: Selection,
        handler: @escaping (Selection) -> Void
    ) -> UIMenu {
        
        let options = Selection.allCases.reversed().map { option in
            UIAction(
                title: option.title,
                image: option.menuIcon,
                state: (current == option) ? .on : .off,
                handler: { _ in
                    UISelectionFeedbackGenerator().selectionChanged()
                    handler(option)
                }
            )
        }
        
        return UIMenu(title: UserText.speedMenuTitle, children: options)
    }
}
