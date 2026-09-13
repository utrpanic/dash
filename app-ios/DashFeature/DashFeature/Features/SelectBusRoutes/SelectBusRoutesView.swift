import ComposableArchitecture
import DashDomain
import SwiftUI

struct SelectBusRoutesView: View {
  let store: StoreOf<SelectBusRoutesFeature>
  private let routeGridColumns = [
    GridItem(
      .adaptive(minimum: 96),
      spacing: r.dimen.spacingXSmall
    )
  ]

  var body: some View {
    ZStack {
      r.color.background
        .ignoresSafeArea()

      VStack(spacing: 0) {
        DashListDivider()

        ScrollView {
          VStack(alignment: .leading, spacing: r.dimen.spacingLarge) {
            busStopSummary
            routesSection
          }
          .padding(.top, r.dimen.spacingLarge)
          .padding(.bottom, r.dimen.spacingLarge)
        }
        .scrollIndicators(.hidden)
      }
    }
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .principal) {
        Text("버스 노선 선택")
          .font(r.font.screenTitle)
          .foregroundStyle(r.color.textPrimary)
      }
      ToolbarItem(placement: .topBarTrailing) {
        Button("완료") {
          store.send(.doneButtonTapped)
        }
        .font(r.font.navigationAction)
        .foregroundStyle(r.color.brandMint)
        .frame(minWidth: r.dimen.minimumTouchTarget)
        .frame(minHeight: r.dimen.minimumTouchTarget)
        .buttonStyle(.plain)
        .disabled(!store.canCompleteSelection)
        .opacity(store.canCompleteSelection ? 1 : r.opacity.disabled)
        .accessibilityHint("선택한 노선을 정류장에 적용합니다")
      }
      .sharedBackgroundVisibility(.hidden)
    }
    .toolbarBackground(r.color.background, for: .navigationBar)
    .toolbarBackground(.visible, for: .navigationBar)
    .task {
      store.send(.task)
    }
  }

  private var busStopSummary: some View {
    VStack(alignment: .leading, spacing: r.dimen.spacingXSmall) {
      Text(store.busStop.name)
        .font(r.font.rowTitle)
        .foregroundStyle(r.color.textPrimary)
        .lineLimit(2)

      Text(verbatim: "정류장 번호 \(store.busStop.id.stopID)")
        .font(r.font.metadata)
        .foregroundStyle(r.color.textSecondary)
    }
    .padding(.horizontal, r.dimen.spacingMedium)
  }

  @ViewBuilder
  private var routesSection: some View {
    if store.isLoadingRoutes {
      ProgressView()
        .frame(maxWidth: .infinity)
        .padding(.vertical, r.dimen.spacingXLarge)
    } else if let routeLoadErrorMessage = store.routeLoadErrorMessage {
      routeLoadErrorState(routeLoadErrorMessage)
    } else if store.routeOptions.isEmpty {
      emptyRoutesState
    } else {
      routeGrid
    }
  }

  private func routeLoadErrorState(_ message: String) -> some View {
    VStack(spacing: r.dimen.spacingMedium) {
      Text("노선 정보를 불러오지 못했습니다.")
        .font(r.font.body)
        .foregroundStyle(r.color.textSecondary)
      Text(message)
        .font(r.font.metadata)
        .foregroundStyle(r.color.textSecondary)
        .multilineTextAlignment(.center)
      Button("다시 시도") {
        store.send(.task)
      }
      .font(r.font.navigationAction)
      .foregroundStyle(r.color.brandMint)
      .buttonStyle(.plain)
    }
    .frame(maxWidth: .infinity)
    .padding(.horizontal, r.dimen.spacingMedium)
    .padding(.vertical, r.dimen.spacingXLarge)
  }

  private var routeGrid: some View {
    VStack(alignment: .leading, spacing: r.dimen.spacingSmall) {
      DashSectionHeader("노선") {
        Text("\(store.selectedRouteIDs.count)개 선택")
          .font(r.font.metadata)
          .foregroundStyle(r.color.textSecondary)
      }

      LazyVGrid(
        columns: routeGridColumns,
        alignment: .leading,
        spacing: r.dimen.spacingXSmall
      ) {
        ForEach(store.routeOptions) { route in
          routeTile(route)
        }
      }
    }
    .padding(.horizontal, r.dimen.spacingMedium)
  }

  private func routeTile(
    _ route: BusRoute
  ) -> some View {
    let isSelected = store.selectedRouteIDs.contains(route.id)

    return Button {
      store.send(.routeTapped(route.id))
    } label: {
      DashSelectableTile(isSelected: isSelected) {
        Text(route.number)
          .font(r.font.routeTileNumber)
          .foregroundStyle(r.color.textPrimary)
          .lineLimit(1)
          .minimumScaleFactor(0.75)
          .frame(maxWidth: .infinity, alignment: .center)
      }
    }
    .buttonStyle(.plain)
    .accessibilityLabel(
      "\(route.number), \(isSelected ? "선택됨" : "선택 안 됨")"
    )
    .accessibilityHint("이 노선의 선택 상태를 변경합니다")
  }

  private var emptyRoutesState: some View {
    Text("이 정류장의 노선 정보가 없습니다.")
      .font(r.font.body)
      .foregroundStyle(r.color.textSecondary)
      .multilineTextAlignment(.center)
    .frame(maxWidth: .infinity)
    .padding(.horizontal, r.dimen.spacingMedium)
    .padding(.vertical, r.dimen.spacingXLarge)
  }
}

#Preview {
  NavigationStack {
    SelectBusRoutesView(
      store: Store(
        initialState: SelectBusRoutesFeature.State(
          boardingPoint: .suwonStation,
          busStop: .suwonStationExit7Outer
        )
      ) {
        SelectBusRoutesFeature()
      } withDependencies: {
        $0.busRouteRepository = EmptyBusRouteRepository()
      }
    )
  }
}
