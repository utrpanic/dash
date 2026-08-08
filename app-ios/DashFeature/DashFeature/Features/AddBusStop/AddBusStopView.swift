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
        Divider()
          .background(r.color.textSecondary.opacity(0.25))
        mapArea
        nearbyStopsSection
      }

      selectButton
        .padding(.horizontal, 16)
    }
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .principal) {
        Text("정류장 추가")
          .font(.system(size: 24, weight: .regular))
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
        .padding(.horizontal, 32)
        .padding(.top, 20)
    }
    .aspectRatio(1, contentMode: .fill)
    .clipped()
  }

  private var searchField: some View {
    HStack(spacing: 12) {
      Image(systemName: "magnifyingglass")
        .font(.system(size: 25, weight: .regular))
        .foregroundStyle(r.color.textSecondary)
      TextField(
        "장소 또는 주소로 지도 이동",
        text: Binding(
          get: { store.query },
          set: { store.send(.queryChanged($0)) }
        )
      )
      .font(.system(size: 20, weight: .regular))
      .foregroundStyle(r.color.textPrimary)
      .textInputAutocapitalization(.never)
    }
    .padding(.horizontal, 18)
    .frame(height: 58)
    .background(r.color.surface, in: Capsule())
    .shadow(color: .black.opacity(0.1), radius: 8, y: 2)
    .accessibilityLabel("장소 또는 주소 검색")
  }

  private var nearbyStopsSection: some View {
    ScrollView {
      LazyVStack(spacing: 0) {
        ForEach(Array(filteredStops.enumerated()), id: \.element.id) { index, stop in
          stopRow(stop, markerLetter: markerLetter(for: index))
          if stop.id != filteredStops.last?.id {
            Divider()
              .background(r.color.textSecondary.opacity(0.25))
          }
        }
      }
      .padding(.bottom, 116)
    }
    .scrollIndicators(.hidden)
    .frame(maxHeight: .infinity)
  }

  private func stopRow(_ stop: BusStop, markerLetter: String) -> some View {
    Button {
      store.send(.stopTapped(stop.id))
    } label: {
      HStack(spacing: 16) {
        marker(for: stop, letter: markerLetter, compact: true)

        VStack(alignment: .leading, spacing: 5) {
          Text(stop.name)
            .font(
              .system(
                size: 20,
                weight: store.selectedStopID == stop.id ? .semibold : .medium
              )
            )
            .foregroundStyle(r.color.textPrimary)
            .multilineTextAlignment(.leading)
          Text(verbatim: "정류장 번호 \(stop.id)")
            .font(.system(size: 16, weight: .regular))
            .foregroundStyle(r.color.textSecondary)
            .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 18)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .background {
      if store.selectedStopID == stop.id {
        ZStack(alignment: .leading) {
          r.color.brandMint.opacity(0.08)
          Rectangle()
            .fill(r.color.brandMint)
            .frame(width: 4)
        }
      }
    }
    .accessibilityLabel("\(stop.name), 정류장 번호 \(stop.id)")
    .accessibilityHint("이 정류장을 선택합니다")
  }

  private var selectButton: some View {
    Button {
      store.send(.selectButtonTapped)
    } label: {
      Text("이 정류장 선택")
        .font(.system(size: 22, weight: .semibold))
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .frame(height: 64)
    }
    .buttonStyle(.plain)
    .background(r.color.brandMint, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    .padding(.top, 12)
    .padding(.bottom, 24)
    .disabled(store.selectedStopID == nil)
    .opacity(store.selectedStopID == nil ? 0.45 : 1)
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
      .font(.system(size: compact ? 17 : 14, weight: .semibold))
      .foregroundStyle(.white)
      .frame(width: compact ? 48 : 32, height: compact ? 48 : 32)
      .background(
        store.selectedStopID == stop.id ? r.color.brandMint : r.color.textSecondary,
        in: Circle()
      )
      .overlay {
        if !compact {
          Circle()
            .stroke(.white.opacity(0.8), lineWidth: 2)
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
