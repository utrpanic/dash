import ComposableArchitecture
import DashDomain
import MapKit
import SwiftUI

struct AddBusStopView: View {
  private static let mapSpanMeters: CLLocationDistance = 300

  @Bindable private var store: StoreOf<AddBusStopFeature>
  @State private var mapPosition: MapCameraPosition

  init(store: StoreOf<AddBusStopFeature>) {
    self.store = store
    if let latitude = store.boardingPoint.centerLatitude,
       let longitude = store.boardingPoint.centerLongitude {
      let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
      _mapPosition = State(initialValue: .region(
        MKCoordinateRegion(
          center: center,
          latitudinalMeters: Self.mapSpanMeters,
          longitudinalMeters: Self.mapSpanMeters
        )
      ))
    } else {
      _mapPosition = State(initialValue: .automatic)
    }
  }

  var body: some View {
    ZStack {
      r.color.background
        .ignoresSafeArea()
      VStack(spacing: 0) {
        DashListDivider()
        mapArea
        nearbyStopsSection
      }
    }
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .principal) {
        Text("정류장 추가")
          .font(r.font.screenTitle)
          .foregroundStyle(r.color.textPrimary)
      }
    }
    .toolbarBackground(r.color.background, for: .navigationBar)
    .toolbarBackground(.visible, for: .navigationBar)
    .task {
      store.send(.task)
    }
    .onChange(of: store.userLocation) { _, location in
      guard let location else { return }
      moveMap(to: CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude))
    }
    .onChange(of: store.availableStops) { _, stops in
      if let stop = stops.first {
        moveMap(to: coordinate(for: stop))
      }
    }
    .onChange(of: store.selectedStopID) { _, selectedStopID in
      guard let selectedStopID,
            let stop = store.availableStops.first(where: { $0.id == selectedStopID })
      else {
        return
      }
      moveMap(to: coordinate(for: stop))
    }
  }

  private var mapArea: some View {
    ZStack(alignment: .top) {
      Map(position: $mapPosition, selection: mapSelection) {
        ForEach(store.availableStops) { stop in
          Annotation(stop.name, coordinate: coordinate(for: stop)) {
            marker(for: stop)
          }
          .tag(stop.id)
        }
      }
      .mapStyle(.standard(elevation: .realistic))

      searchField
        .padding(.horizontal, r.dimen.spacingMedium)
        .padding(.top, r.dimen.spacingLarge)
    }
    .aspectRatio(1, contentMode: .fill)
    .clipped()
  }

  private var searchField: some View {
    HStack(spacing: r.dimen.spacingSmall) {
      Image(systemName: "magnifyingglass")
        .font(.title2.weight(.regular))
        .foregroundStyle(r.color.textSecondary)
      TextField(
        "정류장 이름 또는 번호 검색",
        text: Binding(
          get: { store.query },
          set: { store.send(.queryChanged($0)) }
        )
      )
      .font(r.font.input)
      .foregroundStyle(r.color.textPrimary)
      .textInputAutocapitalization(.never)
    }
    .padding(.horizontal, r.dimen.spacingMedium)
    .frame(minHeight: r.dimen.textFieldHeight)
    .background(r.color.surface, in: Capsule())
    .shadow(
      color: r.color.shadow.opacity(r.opacity.overlayShadow),
      radius: r.dimen.overlayShadowRadius,
      y: r.dimen.overlayShadowYOffset
    )
    .accessibilityLabel("정류장 검색")
  }

  private var nearbyStopsSection: some View {
    ScrollViewReader { proxy in
      ScrollView {
        LazyVStack(spacing: 0) {
          if store.isLoadingStops {
            ProgressView()
              .padding(.vertical, r.dimen.spacingLarge)
          } else if let message = store.stopLoadErrorMessage {
            Text(message)
              .font(r.font.body)
              .foregroundStyle(r.color.textSecondary)
              .padding(.vertical, r.dimen.spacingLarge)
          } else if store.availableStops.isEmpty {
            Text(emptyStopsMessage)
              .font(r.font.body)
              .foregroundStyle(r.color.textSecondary)
              .multilineTextAlignment(.center)
              .padding(.vertical, r.dimen.spacingLarge)
          } else {
            ForEach(Array(store.availableStops.enumerated()), id: \.element.id) { index, stop in
              stopRow(stop, markerLetter: markerLetter(for: index))
                .id(stop.id)
              if stop.id != store.availableStops.last?.id {
                DashListDivider()
              }
            }
          }
        }
      }
      .scrollIndicators(.hidden)
      .frame(maxHeight: .infinity)
      .onChange(of: store.selectedStopID) { _, selectedStopID in
        guard let selectedStopID else { return }
        proxy.scrollTo(selectedStopID, anchor: .top)
      }
    }
  }

  private var emptyStopsMessage: String {
    if !store.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      return "검색 결과가 없습니다."
    }
    return store.locationErrorMessage ?? "주변 정류장이 없습니다."
  }

  private func stopRow(_ stop: BusStop, markerLetter: String) -> some View {
    let isSelected = store.selectedStopID == stop.id

    return DashFlatListRow(
      isSelected: isSelected,
      minHeight: r.dimen.richRowMinHeight
    ) {
      VStack(alignment: .leading, spacing: 0) {
        Button {
          store.send(.stopTapped(stop.id))
        } label: {
          HStack(spacing: r.dimen.spacingMedium) {
            marker(for: stop, letter: markerLetter, compact: true)

            VStack(alignment: .leading, spacing: r.dimen.spacingXSmall) {
              Text(stop.name)
                .font(r.font.rowTitle)
                .foregroundStyle(r.color.textPrimary)
                .multilineTextAlignment(.leading)

              Text("정류장 번호 \(displayNumber(for: stop))")
                .font(r.font.metadata)
                .foregroundStyle(r.color.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
          }
          .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(
          minHeight: r.dimen.richRowMinHeight - r.dimen.rowVerticalPadding * 2
        )
        .accessibilityLabel(
          isSelected
            ? "\(stop.name), 정류장 번호 \(displayNumber(for: stop)), \(routeAccessibilityDescription(for: stop)), 선택됨"
            : "\(stop.name), 정류장 번호 \(displayNumber(for: stop))"
        )
        .accessibilityHint("이 정류장의 상세 정보를 표시합니다")

        if isSelected {
          expandedStopDetails(for: stop)
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    } trailing: {
      EmptyView()
    }
    .transaction { transaction in
      transaction.animation = nil
      transaction.disablesAnimations = true
    }
  }

  private func expandedStopDetails(for stop: BusStop) -> some View {
    VStack(alignment: .leading, spacing: 0) {
      DashListDivider()
        .padding(.top, r.dimen.spacingMedium)

      routeDetails(for: stop)

      if store.routeLoadFailedStopIDs.contains(stop.id) {
        retryButton(for: stop)
      } else {
        addButton
      }
    }
  }

  @ViewBuilder
  private func routeDetails(for stop: BusStop) -> some View {
    VStack(alignment: .leading, spacing: 0) {
      if let routes = store.routeOptionsByStopID[stop.id] {
        if routes.isEmpty {
          Text("운행 노선 없음")
        } else {
          Text(routeNumbers(routes))
            .foregroundStyle(r.color.textPrimary)
            .fixedSize(horizontal: false, vertical: true)
        }
      } else if store.loadingRouteStopIDs.contains(stop.id) {
        Text("경유 노선을 불러오는 중…")
      } else if store.routeLoadFailedStopIDs.contains(stop.id) {
        Text("경유 노선을 불러오지 못했습니다.")
      } else {
        Text("경유 노선 정보 없음")
      }
    }
    .font(r.font.body)
    .foregroundStyle(r.color.textSecondary)
    .multilineTextAlignment(.leading)
    .frame(
      maxWidth: .infinity,
      minHeight: r.dimen.minimumTouchTarget,
      alignment: .leading
    )
  }

  private func retryButton(for stop: BusStop) -> some View {
    Button {
      store.send(.stopTapped(stop.id))
    } label: {
      Label("다시 시도", systemImage: "arrow.clockwise")
        .font(r.font.navigationAction)
        .foregroundStyle(r.color.brandMint)
        .frame(maxWidth: .infinity)
        .frame(minHeight: r.dimen.minimumTouchTarget)
        .overlay {
          RoundedRectangle(cornerRadius: r.dimen.controlRadius, style: .continuous)
            .stroke(r.color.brandMint)
        }
    }
    .buttonStyle(.plain)
    .accessibilityHint("이 정류장의 경유 노선을 다시 불러옵니다")
  }

  private var addButton: some View {
    Button {
      store.send(.selectButtonTapped)
    } label: {
      Text("이 정류장 추가")
    }
    .buttonStyle(DashPrimaryButtonStyle())
    .accessibilityHint("이 정류장을 탑승 지점에 추가합니다")
  }

  private var mapSelection: Binding<BusStop.ID?> {
    Binding(
      get: { store.selectedStopID },
      set: { selectedStopID in
        guard let selectedStopID else { return }
        store.send(.stopTapped(selectedStopID))
      }
    )
  }

  private func coordinate(for stop: BusStop) -> CLLocationCoordinate2D {
    CLLocationCoordinate2D(latitude: stop.latitude, longitude: stop.longitude)
  }

  private func moveMap(to coordinate: CLLocationCoordinate2D) {
    mapPosition = .region(MKCoordinateRegion(
      center: coordinate,
      latitudinalMeters: Self.mapSpanMeters,
      longitudinalMeters: Self.mapSpanMeters
    ))
  }

  private func markerLetter(for index: Int) -> String {
    String(UnicodeScalar(65 + min(index, 25))!)
  }

  private func routeNumbers(_ routes: [BusRoute]) -> String {
    let numbers = routes.map(\.number).sorted { lhs, rhs in
      lhs.localizedStandardCompare(rhs) == .orderedAscending
    }
    let maximumVisibleCount = 6
    let visibleNumbers = numbers.prefix(maximumVisibleCount)
    let suffix = numbers.count > maximumVisibleCount ? " 외 \(numbers.count - maximumVisibleCount)개" : ""
    return visibleNumbers.joined(separator: " · ") + suffix
  }

  private func displayNumber(for stop: BusStop) -> String {
    switch stop.id {
    case let .gyeonggi(stopID):
      String(stopID)
    case let .seoul(stopID, arsID):
      arsID.isEmpty ? String(stopID) : arsID
    }
  }

  private func routeAccessibilityDescription(for stop: BusStop) -> String {
    guard let routes = store.routeOptionsByStopID[stop.id], !routes.isEmpty else {
      return "경유 노선 정보 없음"
    }
    return "경유 노선 \(routeNumbers(routes))"
  }

  private func marker(for stop: BusStop, letter: String? = nil, compact: Bool = false) -> some View {
    Text(letter ?? markerLetter(for: store.availableStops.firstIndex(of: stop) ?? 0))
      .font(compact ? r.font.sectionTitle : r.font.metadata)
      .fontWeight(.semibold)
      .foregroundStyle(.white)
      .frame(
        width: compact ? r.dimen.listMarkerSize : r.dimen.mapMarkerSize,
        height: compact ? r.dimen.listMarkerSize : r.dimen.mapMarkerSize
      )
      .background(
        store.selectedStopID == stop.id ? r.color.brandMint : r.color.textSecondary,
        in: Circle()
      )
      .overlay {
        if !compact {
          Circle()
            .stroke(
              .white.opacity(r.opacity.mapMarkerBorder),
              lineWidth: r.dimen.mapMarkerBorderWidth
            )
        }
      }
  }
}

#Preview {
  NavigationStack {
    AddBusStopView(
      store: Store(initialState: AddBusStopFeature.State(boardingPoint: .suwonStation)) {
        AddBusStopFeature()
      }
    )
  }
}
