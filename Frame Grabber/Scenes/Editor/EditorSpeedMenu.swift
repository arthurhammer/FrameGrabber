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
                return Localized.speedMenuNormalSpeedAction
            case .half:
                return Localized.speedMenuHalfSpeedAction
            case .quarter:
                return Localized.speedMenuQuarterSpeedAction
            case .fine:
                return Localized.speedMenuFineSpeedAction
            case .veryFine:
                return Localized.speedMenuVeryFineSpeedAction
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
            title: Localized.speedMenuTitle,
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
