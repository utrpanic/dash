import SwiftUI

struct DashPrimaryButtonStyle: ButtonStyle {
  var isFloating = false

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(r.font.navigationAction)
      .foregroundStyle(.white)
      .frame(maxWidth: .infinity)
      .frame(minHeight: r.dimen.primaryButtonHeight)
      .background(
        r.color.brandMint,
        in: RoundedRectangle(
          cornerRadius: r.dimen.controlRadius,
          style: .continuous
        )
      )
      .opacity(configuration.isPressed ? r.opacity.pressed : 1)
      .shadow(
        color: isFloating
          ? r.color.shadow.opacity(r.opacity.floatingShadow)
          : .clear,
        radius: r.dimen.floatingShadowRadius,
        y: r.dimen.floatingShadowYOffset
      )
  }
}

struct DashListDivider: View {
  var body: some View {
    Divider()
      .overlay(r.color.textSecondary.opacity(r.opacity.divider))
  }
}

struct DashFlatListRow<Content: View, Trailing: View>: View {
  let isSelected: Bool
  let minHeight: CGFloat
  private let content: Content
  private let trailing: Trailing

  init(
    isSelected: Bool = false,
    minHeight: CGFloat = r.dimen.standardRowMinHeight,
    @ViewBuilder content: () -> Content,
    @ViewBuilder trailing: () -> Trailing
  ) {
    self.isSelected = isSelected
    self.minHeight = minHeight
    self.content = content()
    self.trailing = trailing()
  }

  var body: some View {
    HStack(spacing: r.dimen.spacingXSmall) {
      content
      trailing
    }
    .padding(.horizontal, r.dimen.spacingMedium)
    .padding(.vertical, r.dimen.rowVerticalPadding)
    .frame(minHeight: minHeight)
    .frame(maxWidth: .infinity)
    .background {
      if isSelected {
        ZStack(alignment: .leading) {
          r.color.brandMint.opacity(r.opacity.selectionBackground)
          Rectangle()
            .fill(r.color.brandMint)
            .frame(width: r.dimen.selectionRailWidth)
        }
      }
    }
  }
}

struct DashSelectableCard<Content: View>: View {
  let isSelected: Bool
  let minHeight: CGFloat
  private let content: Content

  init(
    isSelected: Bool,
    minHeight: CGFloat = r.dimen.standardRowMinHeight,
    @ViewBuilder content: () -> Content
  ) {
    self.isSelected = isSelected
    self.minHeight = minHeight
    self.content = content()
  }

  var body: some View {
    DashGroupedSurface {
      HStack(spacing: r.dimen.spacingSmall) {
        content

        ZStack {
          Circle()
            .fill(isSelected ? r.color.brandMint : .clear)
          Circle()
            .stroke(
              isSelected ? r.color.brandMint : r.color.textSecondary,
              lineWidth: r.dimen.selectionIndicatorBorderWidth
            )
          if isSelected {
            Image(systemName: "checkmark")
              .font(.body.weight(.semibold))
              .foregroundStyle(.white)
          }
        }
        .frame(
          width: r.dimen.selectionIndicatorSize,
          height: r.dimen.selectionIndicatorSize
        )
        .frame(
          width: r.dimen.minimumTouchTarget,
          height: r.dimen.minimumTouchTarget
        )
        .accessibilityHidden(true)
      }
      .padding(.horizontal, r.dimen.spacingMedium)
      .padding(.vertical, r.dimen.rowVerticalPadding)
      .frame(minHeight: minHeight)
      .frame(maxWidth: .infinity)
      .background(isSelected ? r.color.brandMint.opacity(r.opacity.selectionBackground) : .clear)
    }
  }
}

struct DashGroupedSurface<Content: View>: View {
  private let content: Content

  init(@ViewBuilder content: () -> Content) {
    self.content = content()
  }

  var body: some View {
    content
      .clipShape(
        RoundedRectangle(
          cornerRadius: r.dimen.surfaceRadius,
          style: .continuous
        )
      )
      .background(
        r.color.surface,
        in: RoundedRectangle(
          cornerRadius: r.dimen.surfaceRadius,
          style: .continuous
        )
      )
      .overlay {
        RoundedRectangle(
          cornerRadius: r.dimen.surfaceRadius,
          style: .continuous
        )
        .stroke(
          r.color.textSecondary.opacity(r.opacity.divider),
          lineWidth: 1
        )
      }
  }
}

struct DashStatusCard<Content: View>: View {
  private let content: Content

  init(@ViewBuilder content: () -> Content) {
    self.content = content()
  }

  var body: some View {
    DashGroupedSurface {
      content
    }
  }
}

struct DashSectionHeader<Trailing: View>: View {
  let title: String
  private let trailing: Trailing

  init(
    _ title: String,
    @ViewBuilder trailing: () -> Trailing
  ) {
    self.title = title
    self.trailing = trailing()
  }

  var body: some View {
    HStack(alignment: .firstTextBaseline) {
      Text(title)
        .font(r.font.sectionTitle)
        .foregroundStyle(r.color.textPrimary)

      Spacer(minLength: r.dimen.spacingSmall)

      trailing
    }
  }
}
