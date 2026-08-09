import ComposableArchitecture
import DashDomain
import SwiftUI

struct SelectBusRoutesView: View {
  let store: StoreOf<SelectBusRoutesFeature>

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
    .safeAreaInset(edge: .bottom) {
      selectedRouteCount
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
      HStack(spacing: 0) {
        Text(store.busStop.name)
          .font(r.font.rowTitle)
          .foregroundStyle(r.color.textPrimary)
          .lineLimit(2)
        Spacer(minLength: r.dimen.spacingXSmall)
        Button(store.allRoutesAreSelected ? "모두 해제" : "모두 선택") {
          store.send(.selectAllButtonTapped)
        }
        .font(r.font.navigationAction)
        .foregroundStyle(r.color.brandMint)
        .frame(minHeight: r.dimen.minimumTouchTarget)
        .buttonStyle(.plain)
        .disabled(store.routeOptions.isEmpty)
        .opacity(store.routeOptions.isEmpty ? r.opacity.disabled : 1)
      }

      Text(verbatim: "정류장 번호 \(store.busStop.id.stationID)")
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
      routeList
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

  private var routeList: some View {
    LazyVStack(spacing: r.dimen.spacingSmall) {
      ForEach(store.routeOptions) { route in
        routeRow(route)
      }
    }
    .padding(.horizontal, r.dimen.spacingMedium)
  }

  private func routeRow(
    _ route: BusRoute
  ) -> some View {
    let isSelected = store.selectedRouteIDs.contains(route.id)

    return Button {
      store.send(.routeTapped(route.id))
    } label: {
      DashSelectableCard(
        isSelected: isSelected,
        minHeight: r.dimen.richRowMinHeight
      ) {
        Text(route.number)
          .font(r.font.routeNumber)
          .foregroundStyle(r.color.textPrimary)
          .frame(maxWidth: .infinity, alignment: .leading)
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

  private var selectedRouteCount: some View {
    Text("\(store.selectedRouteIDs.count)개 노선 선택됨")
      .font(r.font.body)
      .foregroundStyle(r.color.textSecondary)
      .frame(maxWidth: .infinity)
      .padding(.vertical, r.dimen.spacingLarge)
      .background(r.color.background)
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
