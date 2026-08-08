import SwiftUI

struct DashListDivider: View {
  var leadingInset: CGFloat = 0
  var trailingInset: CGFloat = 0

  var body: some View {
    Divider()
      .overlay(r.color.textSecondary.opacity(r.opacity.divider))
      .padding(.leading, leadingInset)
      .padding(.trailing, trailingInset)
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

struct DashGroupedSurface<Content: View>: View {
  private let content: Content

  init(@ViewBuilder content: () -> Content) {
    self.content = content()
  }

  var body: some View {
    content
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
