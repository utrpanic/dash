import ComposableArchitecture
import DashDomain

@Reducer
struct AddBusStopFeature {
  @ObservableState
  struct State: Equatable {
    var boardingPoint: BoardingPoint
    var availableStops: [BusStop] = []
    var query = ""
    var selectedStopID: BusStop.ID?
    var userLocation: UserLocation?
    var locationErrorMessage: String?
    var isLoadingLocation = false
    var isLoadingStops = false
    var stopLoadErrorMessage: String?
    var routeOptionsByStopID: [BusStop.ID: [BusRoute]] = [:]
    var loadingRouteStopIDs: Set<BusStop.ID> = []
    var routeLoadFailedStopIDs: Set<BusStop.ID> = []

    init(boardingPoint: BoardingPoint) {
      self.boardingPoint = boardingPoint
    }
  }

  enum StopLoadError: Error, Equatable {
    case unavailable
  }

  enum Action: Equatable {
    case task
    case locationResponse(Result<UserLocation, UserLocationError>)
    case queryChanged(String)
    case stopResponse(Result<[BusStop], StopLoadError>)
    case routeOptionsResponse(BusStop.ID, Result<[BusRoute], StopLoadError>)
    case stopTapped(BusStop.ID)
    case selectButtonTapped
    case delegate(Delegate)

    enum Delegate: Equatable {
      case busStopSelected(BusStop)
    }
  }

  @Dependency(\.userLocationClient) var userLocationClient
  @Dependency(\.busStopRepository) var busStopRepository
  @Dependency(\.busRouteRepository) var busRouteRepository

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .task:
        guard !state.isLoadingLocation else { return .none }
        state.isLoadingLocation = true
        state.locationErrorMessage = nil
        return .run { send in
          do {
            await send(.locationResponse(.success(try await userLocationClient.requestLocation())))
          } catch let error as UserLocationError {
            await send(.locationResponse(.failure(error)))
          } catch {
            await send(.locationResponse(.failure(.locationUnavailable)))
          }
        }

      case let .locationResponse(result):
        state.isLoadingLocation = false
        switch result {
        case let .success(location):
          state.userLocation = location
          state.locationErrorMessage = nil
          return loadNearbyStops(latitude: location.latitude, longitude: location.longitude, state: &state)
        case .failure(.authorizationDenied):
          state.locationErrorMessage = "위치 권한이 없습니다. 정류장을 검색해주세요."
          return .none
        case .failure(.locationUnavailable):
          state.locationErrorMessage = "현재 위치를 확인할 수 없습니다. 정류장을 검색해주세요."
          return .none
        }

      case let .queryChanged(query):
        state.query = query
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if query.isEmpty {
          guard let location = state.userLocation else {
            state.availableStops = []
            return .none
          }
          return loadNearbyStops(latitude: location.latitude, longitude: location.longitude, state: &state)
        }
        state.isLoadingStops = true
        state.stopLoadErrorMessage = nil
        return .merge(.cancel(id: CancelID.routeRequest), .run { [busStopRepository] send in
          do {
            await send(.stopResponse(.success(try await busStopRepository.searchStops(matching: query))))
          } catch {
            await send(.stopResponse(.failure(.unavailable)))
          }
        }
        .cancellable(id: CancelID.stopRequest, cancelInFlight: true))

      case let .stopResponse(result):
        state.isLoadingStops = false
        switch result {
        case let .success(stops):
          state.availableStops = stops
          state.stopLoadErrorMessage = nil
          state.routeOptionsByStopID = [:]
          state.loadingRouteStopIDs = []
          state.routeLoadFailedStopIDs = []
          if !stops.contains(where: { $0.id == state.selectedStopID }) {
            state.selectedStopID = nil
          }
        case .failure:
          state.availableStops = []
          state.stopLoadErrorMessage = "정류장 정보를 불러오지 못했습니다."
          state.routeOptionsByStopID = [:]
          state.loadingRouteStopIDs = []
          state.routeLoadFailedStopIDs = []
        }
        return .none

      case let .routeOptionsResponse(stopID, result):
        state.loadingRouteStopIDs.remove(stopID)
        switch result {
        case let .success(routes):
          state.routeOptionsByStopID[stopID] = routes
          state.routeLoadFailedStopIDs.remove(stopID)
        case .failure:
          state.routeLoadFailedStopIDs.insert(stopID)
        }
        return .none

      case let .stopTapped(stopID):
        state.selectedStopID = stopID
        if state.loadingRouteStopIDs.contains(stopID) {
          return .none
        }
        if state.routeOptionsByStopID[stopID] != nil {
          state.loadingRouteStopIDs = []
          return .cancel(id: CancelID.routeRequest)
        }
        guard let stop = state.availableStops.first(where: { $0.id == stopID }) else {
          return .none
        }
        state.loadingRouteStopIDs = [stopID]
        state.routeLoadFailedStopIDs.remove(stopID)
        return loadRoutes(for: stop)

      case .selectButtonTapped:
        guard let selectedStopID = state.selectedStopID,
              let stop = state.availableStops.first(where: { $0.id == selectedStopID })
        else {
          return .none
        }
        return .send(.delegate(.busStopSelected(stop)))

      case .delegate:
        return .none
      }
    }
  }

  private enum CancelID { case stopRequest, routeRequest }

  private func loadNearbyStops(
    latitude: Double,
    longitude: Double,
    state: inout State
  ) -> Effect<Action> {
    state.isLoadingStops = true
    state.stopLoadErrorMessage = nil
    return .merge(.cancel(id: CancelID.routeRequest), .run { [busStopRepository] send in
      do {
        await send(.stopResponse(.success(
          try await busStopRepository.fetchNearbyStops(latitude: latitude, longitude: longitude)
        )))
      } catch {
        await send(.stopResponse(.failure(.unavailable)))
      }
    }
    .cancellable(id: CancelID.stopRequest, cancelInFlight: true))
  }

  private func loadRoutes(for stop: BusStop) -> Effect<Action> {
    .run { [busRouteRepository] send in
      do {
        await send(.routeOptionsResponse(stop.id, .success(
          try await busRouteRepository.fetchRoutes(at: stop)
        )))
      } catch {
        await send(.routeOptionsResponse(stop.id, .failure(.unavailable)))
      }
    }
    .cancellable(id: CancelID.routeRequest, cancelInFlight: true)
  }
}
