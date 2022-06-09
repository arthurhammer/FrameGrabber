import ThumbnailSlider
import UIKit

enum EditorSpeedMenu {
        
    enum Selection: Float, CaseIterable {
        case normal = 1
        case half = 0.5
        case quarter = 0.25
        case fine = 0.1
        case veryFine = 0.01
        
        var title: String {
            switch self {
            case .normal:
                return UserText.speedMenuNormalSpeedAction
            case .half:
                return UserText.speedMenuHalfSpeedAction
            case .quarter:
                return UserText.speedMenuQuarterSpeedAction
            case .fine:
                return UserText.speedMenuFineSpeedAction
            case .veryFine:
                return UserText.speedMenuVeryFineSpeedAction
            }
        }
        
        var menuIcon: UIImage? {
            switch self {
            case .normal:
                return nil
            default:
                return buttonIcon?.applyingSymbolConfiguration(.init(scale: .large))
            }
        }
        
        var buttonIcon: UIImage? {
            let icon = { (systemName: String) -> UIImage? in
                if #available(iOS 15, *) {
                    return UIImage(systemName: systemName)?.applyingSymbolConfiguration(.init(hierarchicalColor: .label))
                } else {
                    return UIImage(systemName: systemName)
                }
            }
            
            switch self {
            case .normal:
                return icon("speedometer")
            case .half:
                return icon("50.circle")
            case .quarter:
                return icon("25.circle")
            case .fine:
                return icon("10.circle")
            case .veryFine:
                return icon("01.circle")
            }
        }
    }

    static var defaultSpeed: Selection {
        assert(!Selection.allCases.isEmpty)
        return Selection.allCases.first!
    }

    static func menu(with current: Selection, handler: @escaping (Selection) -> Void) -> UIMenu {
        let items = Selection.allCases.map { option in
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
        
        assert(!Selection.allCases.isEmpty)
        let defaultItem = items.first!
        let otherItems = items.dropFirst()
        
        return UIMenu(
            title: UserText.speedMenuTitle,
            children: [
                defaultItem,
                UIMenu(options: .displayInline, children: Array(otherItems))
            ]
        )
    }
}

// MARK: - ScrubbingThumbnailSlider Speeds

extension EditorSpeedMenu.Selection {
    
    var scrubbingSpeed: ScrubbingThumbnailSlider.Speed {
        .init(speed: rawValue, verticalDistance: 0)
    }
    
    init(_ scrubbingSpeed: ScrubbingThumbnailSlider.Speed) {
        self = Self(scrubbingSpeed.speed) ?? EditorSpeedMenu.defaultSpeed
    }
}
