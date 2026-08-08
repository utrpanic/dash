import ComposableArchitecture
import SwiftUI

struct CurrentBoardingPointView: View {
  @Bindable private var store: StoreOf<CurrentBoardingPointFeature>

  init(store: StoreOf<CurrentBoardingPointFeature>) {
    self.store = store
  }

  var body: some View {
    content
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          CurrentBoardingPointNavigationTitleView(store: store)
            .fixedSize(horizontal: true, vertical: false)
            .transaction {
              $0.animation = nil
              $0.disablesAnimations = true
            }
        }
        ToolbarItem(placement: .topBarTrailing) {
          CurrentBoardingPointNavigationTrailingView(store: store)
        }
        .sharedBackgroundVisibility(.hidden)
      }
      .toolbarBackground(r.color.background, for: .navigationBar)
      .toolbarBackground(.visible, for: .navigationBar)
  }

  private var content: some View {
    ZStack {
      r.color.background
        .ignoresSafeArea()
      VStack(spacing: 0) {
        DashListDivider()
        if store.isLoadingUpcomingBuses {
          Spacer()
          ProgressView()
            .frame(maxWidth: .infinity)
          Spacer()
        } else if let boardingPointSelectionMessage {
          Spacer()
          Text(boardingPointSelectionMessage)
            .font(r.font.body)
            .foregroundStyle(r.color.textSecondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
          Spacer()
        } else if let errorMessage = store.upcomingBusesErrorMessage {
          Spacer()
          Text(errorMessage)
            .font(r.font.body)
            .foregroundStyle(r.color.textSecondary)
            .frame(maxWidth: .infinity)
          Spacer()
        } else if !store.selectedBoardingPointHasSelectedRoutes {
          Spacer()
          VStack(spacing: r.dimen.spacingXSmall) {
            Image(systemName: "bus")
              .font(.title2.weight(.regular))
              .foregroundStyle(r.color.textSecondary)
            Text("선택된 버스 노선이 없습니다.")
              .font(r.font.body)
              .foregroundStyle(r.color.textSecondary)
          }
          .frame(maxWidth: .infinity)
          Spacer()
        } else if store.upcomingBuses.isEmpty {
          Spacer()
          VStack(spacing: r.dimen.spacingXSmall) {
            Image(systemName: "bus")
              .font(.title2.weight(.regular))
              .foregroundStyle(r.color.textSecondary)
            Text("도착 예정인 버스가 없습니다.")
              .font(r.font.body)
              .foregroundStyle(r.color.textSecondary)
          }
          .frame(maxWidth: .infinity)
          Spacer()
        } else {
          ScrollView {
            BoardingPointView(
              upcomingBuses: Array(store.upcomingBuses.sortedByArrival.prefix(5))
            )
            .padding(.top, r.dimen.spacingSmall)
            .padding(.bottom, r.dimen.utilityButtonSize * 2)
          }
          .scrollIndicators(.hidden)
        }
      }
      .padding(.horizontal, r.dimen.spacingMedium)
      VStack {
        Spacer()
        HStack {
          Spacer()
          floatingButtons
        }
      }
      .padding(.trailing, r.dimen.spacingXLarge)
      .padding(.bottom, r.dimen.spacingXLarge)
      .ignoresSafeArea(.container, edges: [.bottom, .trailing])
    }
    .task {
      store.send(.task)
    }
  }

  private var floatingButtons: some View {
    VStack(spacing: r.dimen.spacingMedium) {
      locationButton
      refreshButton
        .overlay(alignment: .bottom) {
          elapsedTimeLabel
            .offset(y: 20)
            .allowsHitTesting(false)
        }
    }
  }

  private var locationButton: some View {
    Button {
      store.send(.locationButtonTapped)
    } label: {
      Image(systemName: "location.fill")
        .font(.title3.weight(.semibold))
        .foregroundStyle(r.color.brandMint)
        .frame(
          width: r.dimen.utilityButtonSize,
          height: r.dimen.utilityButtonSize
        )
        .background(r.color.surface, in: Circle())
        .shadow(
          color: r.color.shadow.opacity(r.opacity.floatingShadow),
          radius: r.dimen.floatingShadowRadius,
          y: r.dimen.floatingShadowYOffset
        )
    }
    .buttonStyle(.plain)
    .disabled(areFloatingButtonsDisabled)
    .opacity(areFloatingButtonsDisabled ? r.opacity.disabled : 1)
    .accessibilityLabel("현재 위치")
  }

  private var refreshButton: some View {
    Button {
      store.send(.refreshButtonTapped)
    } label: {
      Image(systemName: "arrow.clockwise")
        .font(.title2.weight(.semibold))
        .foregroundStyle(.white)
        .frame(
          width: r.dimen.utilityButtonSize,
          height: r.dimen.utilityButtonSize
        )
        .background(r.color.brandMint, in: Circle())
        .shadow(
          color: r.color.shadow.opacity(r.opacity.floatingShadow),
          radius: r.dimen.floatingShadowRadius,
          y: r.dimen.floatingShadowYOffset
        )
    }
    .buttonStyle(.plain)
    .disabled(areFloatingButtonsDisabled)
    .opacity(areFloatingButtonsDisabled ? r.opacity.disabled : 1)
    .accessibilityLabel("새로고침")
  }

  @ViewBuilder
  private var elapsedTimeLabel: some View {
    if !store.isLoadingUpcomingBuses, let lastUpdatedAt = store.lastUpdatedAt {
      TimelineView(.periodic(from: .now, by: 1)) { context in
        if context.date.timeIntervalSince(lastUpdatedAt) >= 10 {
          Text(elapsedTimeText(from: lastUpdatedAt, to: context.date))
            .font(r.font.caption)
            .monospacedDigit()
            .foregroundStyle(r.color.textSecondary.opacity(r.opacity.subdued))
            .frame(width: r.dimen.utilityButtonSize)
            .accessibilityLabel(
              elapsedTimeAccessibilityLabel(from: lastUpdatedAt, to: context.date)
            )
        }
      }
    }
  }

  private var areFloatingButtonsDisabled: Bool {
    store.isLoadingUpcomingBuses || store.boardingPointIsNotAvailable
  }

  private func elapsedTimeText(from startDate: Date, to endDate: Date) -> String {
    let elapsedSeconds = max(Int(endDate.timeIntervalSince(startDate)), 0)
    if elapsedSeconds < 60 {
      return "\(elapsedSeconds)s ago"
    }
    if elapsedSeconds < 60 * 60 {
      return "\(elapsedSeconds / 60)m ago"
    }
    return "\(elapsedSeconds / 60 / 60)h ago"
  }

  private func elapsedTimeAccessibilityLabel(from startDate: Date, to endDate: Date) -> String {
    let elapsedSeconds = max(Int(endDate.timeIntervalSince(startDate)), 0)
    if elapsedSeconds < 60 {
      let unit = elapsedSeconds == 1 ? "second" : "seconds"
      return "Updated \(elapsedSeconds) \(unit) ago"
    }
    if elapsedSeconds < 60 * 60 {
      let elapsedMinutes = elapsedSeconds / 60
      let unit = elapsedMinutes == 1 ? "minute" : "minutes"
      return "Updated \(elapsedMinutes) \(unit) ago"
    }
    let elapsedHours = elapsedSeconds / 60 / 60
    let unit = elapsedHours == 1 ? "hour" : "hours"
    return "Updated \(elapsedHours) \(unit) ago"
  }

  private var boardingPointSelectionMessage: String? {
    switch store.boardingPointSelection {
    case .locating:
      return "현재 위치를 확인하고 있습니다."
    case .locationPermissionDenied:
      return "위치 권한이 없습니다.\n상단에서 목적지를 선택해주세요."
    case .locationUnavailable:
      return "현재 위치를 확인할 수 없습니다.\n상단에서 목적지를 선택해주세요."
    case .selected:
      return nil
    }
  }
}

private struct CurrentBoardingPointNavigationTitleView: View {
  @Bindable var store: StoreOf<CurrentBoardingPointFeature>

  var body: some View {
    Button {
      store.send(.nextBoardingPointButtonTapped)
    } label: {
      HStack(spacing: r.dimen.spacingXSmall) {
        Image(systemName: "location.circle.fill")
          .symbolRenderingMode(.palette)
          .font(.title2.weight(.semibold))
          .foregroundStyle(.white, r.color.brandMint)
        boardingPointTitleLabel
      }
    }
    .buttonStyle(.plain)
    .disabled(
      store.boardingPointSelection == .locating
        || !store.hasBoardingPointWithSelectedRoutes
    )
  }

  private var boardingPointTitleLabel: some View {
    let (title, showTrailingIcon) = switch store.boardingPointSelection {
    case .locating:
      ("위치 확인 중…", false)
    case .locationPermissionDenied:
      ("위치 권한 없음", false)
    case .locationUnavailable:
      ("위치 확인 불가", false)
    case let .selected(boardingPointID):
      (store.boardingPoints.first { $0.id == boardingPointID }?.name ?? "", true)
    }
    return HStack(spacing: 0) {
      Text(title)
        .font(r.font.screenTitle)
        .foregroundStyle(boardingPointTitleColor)
        .lineLimit(1)
        .frame(maxWidth: 160, alignment: .leading)
      if showTrailingIcon {
        Spacer()
          .frame(width: r.dimen.spacingXXSmall)
        Image(systemName: "chevron.right")
          .font(.body.weight(.medium))
          .foregroundStyle(r.color.textSecondary)
      }
      Spacer()
        .frame(width: r.dimen.spacingXSmall)
    }
  }

  private var boardingPointTitleColor: Color {
    switch store.boardingPointSelection {
    case .selected:
      return r.color.textPrimary
    case .locating, .locationPermissionDenied, .locationUnavailable:
      return r.color.textSecondary
    }
  }
}

private struct CurrentBoardingPointNavigationTrailingView: View {
  let store: StoreOf<CurrentBoardingPointFeature>

  var body: some View {
    HStack(spacing: 0) {
      Button {
        store.send(.editButtonTapped)
      } label: {
        Image(systemName: "square.and.pencil")
          .frame(
            width: r.dimen.minimumTouchTarget,
            height: r.dimen.minimumTouchTarget
          )
      }
      .tint(r.color.textSecondary)
      .disabled(store.boardingPointIsNotAvailable)
      .accessibilityLabel("편집")
      Button {
        store.send(.listButtonTapped)
      } label: {
        Image(systemName: "list.bullet")
          .frame(
            width: r.dimen.minimumTouchTarget,
            height: r.dimen.minimumTouchTarget
          )
      }
      .tint(r.color.textSecondary)
      .accessibilityLabel("목록")
    }
  }
}

#Preview("Light") {
  NavigationStack {
    CurrentBoardingPointView(
      store: Store(initialState: .preview) {
        CurrentBoardingPointFeature()
      }
    )
  }
  .preferredColorScheme(.light)
}

#Preview("Dark") {
  NavigationStack {
    CurrentBoardingPointView(
      store: Store(initialState: .preview) {
        CurrentBoardingPointFeature()
      }
    )
  }
  .preferredColorScheme(.dark)
}

private extension CurrentBoardingPointFeature.State {
  static var preview: Self {
    var state = Self()
    state.boardingPointSelection = .selected(BoardingPoint.suwonStation.id)
    state.hasRequestedInitialLocation = true
    state.upcomingBuses = .mock
    state.lastUpdatedAt = .now.addingTimeInterval(-12)
    return state
  }
}
