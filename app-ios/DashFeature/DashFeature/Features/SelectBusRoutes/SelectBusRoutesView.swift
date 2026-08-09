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

      Text(verbatim: "정류장 번호 \(store.busStop.id)")
        .font(r.font.metadata)
        .foregroundStyle(r.color.textSecondary)
    }
    .padding(.horizontal, r.dimen.spacingMedium)
  }

  @ViewBuilder
  private var routesSection: some View {
    if store.routeOptions.isEmpty {
      emptyRoutesState
    } else {
      routeList
    }
  }

  private var routeList: some View {
    LazyVStack(spacing: r.dimen.spacingSmall) {
      ForEach(store.routeOptions) { option in
        routeRow(option)
      }
    }
    .padding(.horizontal, r.dimen.spacingMedium)
  }

  private func routeRow(
    _ option: SelectBusRoutesFeature.State.RouteOption
  ) -> some View {
    let isSelected = store.selectedRouteIDs.contains(option.id)

    return Button {
      store.send(.routeTapped(option.id))
    } label: {
      DashSelectableCard(
        isSelected: isSelected,
        minHeight: r.dimen.richRowMinHeight
      ) {
        HStack(spacing: r.dimen.spacingMedium) {
          Text(option.route.number)
            .font(r.font.routeNumber)
            .foregroundStyle(r.color.textPrimary)
            .frame(minWidth: r.dimen.standardRowMinHeight, alignment: .leading)

          routeDetails(option)
        }
      }
    }
    .buttonStyle(.plain)
    .accessibilityLabel(
      "\(option.route.number), \(routeDescription(option)), \(isSelected ? "선택됨" : "선택 안 됨")"
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

  @ViewBuilder
  private func routeDetails(
    _ option: SelectBusRoutesFeature.State.RouteOption
  ) -> some View {
    VStack(alignment: .leading, spacing: r.dimen.spacingXXSmall) {
      Text(
        option.directionName.isEmpty
          ? routeRegion(option.route)
          : directionText(option.directionName)
      )
      .font(r.font.body)
      .foregroundStyle(
        option.directionName.isEmpty ? r.color.textSecondary : r.color.textPrimary
      )

      if !option.nextStopName.isEmpty {
        Text("다음: \(option.nextStopName)")
          .font(r.font.body)
          .foregroundStyle(r.color.textSecondary)
      }
    }
    .multilineTextAlignment(.leading)
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private func routeDescription(
    _ option: SelectBusRoutesFeature.State.RouteOption
  ) -> String {
    var components = [
      option.directionName.isEmpty
        ? routeRegion(option.route)
        : directionText(option.directionName)
    ]
    if !option.nextStopName.isEmpty {
      components.append("다음 \(option.nextStopName)")
    }
    return components.joined(separator: ", ")
  }

  private func directionText(_ directionName: String) -> String {
    directionName.hasSuffix("방면") ? directionName : "\(directionName) 방면"
  }

  private func routeRegion(_ route: BusRoute) -> String {
    switch route.region {
    case .gyeonggi:
      return "경기 버스"
    case .seoul:
      return "서울 버스"
    }
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
      }
    )
  }
}
