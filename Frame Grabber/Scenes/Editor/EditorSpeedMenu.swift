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
        
        var icon: UIImage? {
            let icon: UIImage?
            
            switch self {
            case .normal: return nil
            case .half: icon = UIImage(systemName: "50.circle")
            case .quarter: icon = UIImage(systemName: "25.circle")
            case .fine: icon = UIImage(systemName: "10.circle")
            case .veryFine: icon = UIImage(systemName: "01.circle")
            }
            
            return icon?.applyingSymbolConfiguration(.init(scale: .large))
        }
        
        var scrubbingSpeed: ScrubbingThumbnailSlider.Speed {
            .init(speed: rawValue, verticalDistance: 0)
        }
    }
    
    static var defaultScrubbingSpeed: ScrubbingThumbnailSlider.Speed {
        Selection.allCases.first!.scrubbingSpeed
    }
    
    @available(iOS 14, *)
    static func menu(
        withCurrentSelection current: Selection,
        handler: @escaping (Selection) -> Void
    ) -> UIMenu {
        
        let options = Selection.allCases.reversed().map { option in
            UIAction(
                title: option.title,
                image: option.icon,
                state: (current == option) ? .on : .off,
                handler: { _ in
                    UISelectionFeedbackGenerator().selectionChanged()
                    handler(option)
                }
            )
        }
        
        return UIMenu(title: UserText.speedMenuTitle, children: options)
    }
    
    @available(iOS 14, *)
    static func menu(
        withCurrentSpeed current: ScrubbingThumbnailSlider.Speed,
        handler: @escaping (Selection) -> Void
    ) -> UIMenu {
        let selection = Selection(current.speed) ?? .normal
        return menu(withCurrentSelection: selection, handler: handler)
    }
}
