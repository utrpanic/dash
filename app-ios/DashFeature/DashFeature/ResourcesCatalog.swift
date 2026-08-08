import SwiftUI

enum r {
  enum color {
    static let background = Color("background", bundle: .module)
    static let brandMint = Color("brand-mint", bundle: .module)
    static let textPrimary = Color("text-primary", bundle: .module)
    static let textSecondary = Color("text-secondary", bundle: .module)
    static let shadow = Color("shadow", bundle: .module)
    static let surface = Color("surface", bundle: .module)
  }

  enum font {
    static let screenTitle = Font.system(size: 24, weight: .regular)
    static let sectionTitle = Font.system(size: 17, weight: .semibold)
    static let input = Font.system(size: 20, weight: .regular)
    static let rowTitle = Font.system(size: 20, weight: .medium)
    static let selectedRowTitle = Font.system(size: 20, weight: .semibold)
    static let routeNumber = Font.system(size: 32, weight: .semibold)
    static let body = Font.system(size: 16, weight: .regular)
    static let metadata = Font.system(size: 14, weight: .regular)
    static let caption = Font.system(size: 12, weight: .regular)
    static let navigationAction = Font.system(size: 17, weight: .semibold)
    static let arrivalRoute = Font.system(size: 40, weight: .semibold)
    static let arrivalValue = Font.system(size: 48, weight: .regular)
  }

  enum dimen {
    static let spacingXXSmall: CGFloat = 4
    static let spacingXSmall: CGFloat = 8
    static let spacingSmall: CGFloat = 12
    static let spacingMedium: CGFloat = 16
    static let spacingLarge: CGFloat = 24
    static let spacingXLarge: CGFloat = 32

    static let minimumTouchTarget: CGFloat = 44
    static let textFieldHeight: CGFloat = 52
    static let primaryButtonHeight: CGFloat = 56
    static let utilityButtonSize: CGFloat = 64
    static let compactRowMinHeight: CGFloat = 56
    static let standardRowMinHeight: CGFloat = 72
    static let richRowMinHeight: CGFloat = 88
    static let rowVerticalPadding: CGFloat = 14
    static let selectionRailWidth: CGFloat = 4
    static let selectionIndicatorSize: CGFloat = 28
    static let selectionIndicatorBorderWidth: CGFloat = 2
    static let mapMarkerSize: CGFloat = 32
    static let listMarkerSize: CGFloat = 48
    static let mapMarkerBorderWidth: CGFloat = 2
    static let floatingShadowRadius: CGFloat = 8
    static let floatingShadowYOffset: CGFloat = 3
    static let overlayShadowRadius: CGFloat = 8
    static let overlayShadowYOffset: CGFloat = 2

    static let controlRadius: CGFloat = 12
    static let surfaceRadius: CGFloat = 16
  }

  enum opacity {
    static let selectionBackground = 0.08
    static let disabled = 0.45
    static let divider = 0.25
    static let floatingShadow = 0.12
    static let overlayShadow = 0.10
    static let mapMarkerBorder = 0.8
    static let pressed = 0.8
    static let subdued = 0.6
  }
}
