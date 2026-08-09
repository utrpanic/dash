import ComposableArchitecture
import DashDomain
import Foundation

@Reducer
struct SelectBusRoutesFeature {
  @ObservableState
  struct State: Equatable {
    let busStop: BusStop
    var routeOptions: [BusRoute]
    var selectedRouteIDs: Set<BusRoute.ID>
    var isLoadingRoutes = false
    var routeLoadErrorMessage: String?

    init(
      boardingPoint: BoardingPoint,
      busStop: BusStop,
      availableRoutes: [BusRoute] = []
    ) {
      self.busStop = busStop

      let selectedRoutes = boardingPoint.routes[busStop] ?? []
      var optionsByID: [BusRoute.ID: BusRoute] = [:]
      for route in availableRoutes {
        optionsByID[route.id] = route
      }
      for route in selectedRoutes where optionsByID[route.id] == nil {
        optionsByID[route.id] = route
      }

      self.routeOptions = optionsByID.values.sorted {
        let comparison = $0.number.localizedStandardCompare($1.number)
        if comparison == .orderedSame {
          return $0.id < $1.id
        }
        return comparison == .orderedAscending
      }
      self.selectedRouteIDs = Set(selectedRoutes.map(\.id))
    }

    var allRoutesAreSelected: Bool {
      !routeOptions.isEmpty && routeOptions.allSatisfy { selectedRouteIDs.contains($0.id) }
    }
  }

  enum Action: Equatable {
    case task
    case routeOptionsResponse(RouteOptionsResponse)
    case routeTapped(BusRoute.ID)
    case selectAllButtonTapped
    case doneButtonTapped
    case delegate(Delegate)

    enum Delegate: Equatable {
      case selectionCompleted(BusStop, Set<BusRoute>)
    }
  }

  enum RouteOptionsResponse: Equatable {
    case success([BusRoute])
    case failure(String)
  }

  @Dependency(\.gyeonggiBusStationAPIClient) var gyeonggiBusStationAPIClient
  @Dependency(\.seoulBusStationAPIClient) var seoulBusStationAPIClient

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .task:
        guard !state.isLoadingRoutes else {
          return .none
        }
        state.isLoadingRoutes = true
        state.routeLoadErrorMessage = nil
        let busStopID = state.busStop.id
        return .run { send in
          do {
            let routes: [BusRoute]
            switch busStopID {
            case let .gyeonggi(stationID):
              routes = try await gyeonggiBusStationAPIClient.fetchRoutes(stationID)
            case let .seoul(_, arsID):
              routes = try await seoulBusStationAPIClient.fetchRoutes(arsID)
            }
            await send(.routeOptionsResponse(.success(routes)))
          } catch {
            await send(.routeOptionsResponse(.failure(String(describing: error))))
          }
        }

      case let .routeOptionsResponse(.success(routes)):
        state.isLoadingRoutes = false
        state.routeLoadErrorMessage = nil
        updateRouteOptions(&state, with: routes)
        return .none

      case let .routeOptionsResponse(.failure(message)):
        state.isLoadingRoutes = false
        state.routeLoadErrorMessage = message
        return .none

      case let .routeTapped(routeID):
        guard state.routeOptions.contains(where: { $0.id == routeID }) else {
          return .none
        }
        if state.selectedRouteIDs.contains(routeID) {
          state.selectedRouteIDs.remove(routeID)
        } else {
          state.selectedRouteIDs.insert(routeID)
        }
        return .none

      case .selectAllButtonTapped:
        if state.allRoutesAreSelected {
          state.selectedRouteIDs.removeAll()
        } else {
          state.selectedRouteIDs = Set(state.routeOptions.map(\.id))
        }
        return .none

      case .doneButtonTapped:
        let selectedRoutes = Set(
          state.routeOptions
            .filter { state.selectedRouteIDs.contains($0.id) }
        )
        return .send(.delegate(.selectionCompleted(state.busStop, selectedRoutes)))

      case .delegate:
        return .none
      }
    }
  }

  private func updateRouteOptions(
    _ state: inout State,
    with routes: [BusRoute]
  ) {
    var optionsByID = Dictionary(
      uniqueKeysWithValues: state.routeOptions.map { ($0.id, $0) }
    )
    for route in routes {
      optionsByID[route.id] = route
    }
    state.routeOptions = optionsByID.values.sorted {
      let comparison = $0.number.localizedStandardCompare($1.number)
      if comparison == .orderedSame {
        return $0.id < $1.id
      }
      return comparison == .orderedAscending
    }
  }
}
