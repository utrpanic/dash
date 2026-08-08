import ComposableArchitecture
import MapKit
import SwiftUI

struct AddBusStopView: View {
  @Bindable private var store: StoreOf<AddBusStopFeature>
  @State private var mapPosition: MapCameraPosition

  init(store: StoreOf<AddBusStopFeature>) {
    self.store = store
    let center = CLLocationCoordinate2D(
      latitude: store.boardingPoint.centerLatitude,
      longitude: store.boardingPoint.centerLongitude
    )
    _mapPosition = State(initialValue: .region(
      MKCoordinateRegion(
        center: center,
        latitudinalMeters: 900,
        longitudinalMeters: 900
      )
    ))
  }

  var body: some View {
    ZStack(alignment: .bottom) {
      r.color.background
        .ignoresSafeArea()
      VStack(spacing: 0) {
        DashListDivider()
        mapArea
        nearbyStopsSection
      }

      selectButton
        .padding(.horizontal, r.dimen.spacingMedium)
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
    .onChange(of: store.query) { _, _ in
      if let stop = filteredStops.first {
        moveMap(to: coordinate(for: stop))
      }
    }
  }

  private var mapArea: some View {
    ZStack(alignment: .top) {
      Map(position: $mapPosition, selection: mapSelection) {
        ForEach(filteredStops) { stop in
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
        "장소 또는 주소로 지도 이동",
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
    .accessibilityLabel("장소 또는 주소 검색")
  }

  private var nearbyStopsSection: some View {
    ScrollView {
      LazyVStack(spacing: 0) {
        ForEach(Array(filteredStops.enumerated()), id: \.element.id) { index, stop in
          stopRow(stop, markerLetter: markerLetter(for: index))
          if stop.id != filteredStops.last?.id {
            DashListDivider.list
          }
        }
      }
      .padding(.bottom, selectButtonContentInset)
    }
    .scrollIndicators(.hidden)
    .frame(maxHeight: .infinity)
  }

  private func stopRow(_ stop: BusStop, markerLetter: String) -> some View {
    let isSelected = store.selectedStopID == stop.id

    return Button {
      store.send(.stopTapped(stop.id))
    } label: {
      DashFlatListRow(
        isSelected: isSelected,
        minHeight: r.dimen.richRowMinHeight
      ) {
        HStack(spacing: r.dimen.spacingMedium) {
          marker(for: stop, letter: markerLetter, compact: true)

          VStack(alignment: .leading, spacing: r.dimen.spacingXSmall) {
            Text(stop.name)
              .font(isSelected ? r.font.selectedRowTitle : r.font.rowTitle)
              .foregroundStyle(r.color.textPrimary)
              .multilineTextAlignment(.leading)
            Text(verbatim: "정류장 번호 \(stop.id)")
              .font(r.font.body)
              .foregroundStyle(r.color.textSecondary)
              .lineLimit(2)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
        }
      } trailing: {
        EmptyView()
      }
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityLabel(
      isSelected
        ? "\(stop.name), 정류장 번호 \(stop.id), 선택됨"
        : "\(stop.name), 정류장 번호 \(stop.id)"
    )
    .accessibilityHint("이 정류장을 선택합니다")
  }

  private var selectButton: some View {
    Button {
      store.send(.selectButtonTapped)
    } label: {
      Text("이 정류장 선택")
    }
    .buttonStyle(DashPrimaryButtonStyle(isFloating: true))
    .padding(.top, r.dimen.spacingSmall)
    .padding(.bottom, r.dimen.spacingLarge)
    .disabled(store.selectedStopID == nil)
    .opacity(store.selectedStopID == nil ? r.opacity.disabled : 1)
    .accessibilityHint("선택한 정류장을 탑승 지점에 추가합니다")
  }

  private var filteredStops: [BusStop] {
    let query = store.query.trimmingCharacters(in: .whitespacesAndNewlines)
    let stops = query.isEmpty
      ? store.availableStops
      : store.availableStops.filter {
        $0.name.localizedCaseInsensitiveContains(query)
          || ($0.alias?.localizedCaseInsensitiveContains(query) ?? false)
          || String($0.id).contains(query)
      }
    return stops.sorted { distance(to: $0) < distance(to: $1) }
  }

  private var selectButtonContentInset: CGFloat {
    r.dimen.primaryButtonHeight
      + r.dimen.spacingSmall
      + r.dimen.spacingLarge * 2
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

  private func distance(to stop: BusStop) -> CLLocationDistance {
    let center = store.userLocation.map {
      CLLocation(latitude: $0.latitude, longitude: $0.longitude)
    } ?? CLLocation(latitude: store.boardingPoint.centerLatitude, longitude: store.boardingPoint.centerLongitude)
    return center.distance(from: CLLocation(latitude: stop.latitude, longitude: stop.longitude))
  }

  private func coordinate(for stop: BusStop) -> CLLocationCoordinate2D {
    CLLocationCoordinate2D(latitude: stop.latitude, longitude: stop.longitude)
  }

  private func moveMap(to coordinate: CLLocationCoordinate2D) {
    mapPosition = .region(MKCoordinateRegion(center: coordinate, latitudinalMeters: 900, longitudinalMeters: 900))
  }

  private func markerLetter(for index: Int) -> String {
    String(UnicodeScalar(65 + min(index, 25))!)
  }

  private func marker(for stop: BusStop, letter: String? = nil, compact: Bool = false) -> some View {
    Text(letter ?? markerLetter(for: filteredStops.firstIndex(of: stop) ?? 0))
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
