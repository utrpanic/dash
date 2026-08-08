import ComposableArchitecture
import Foundation

@Reducer
struct BusRouteSelectionFeature {
  @ObservableState
  struct State: Equatable {
    struct RouteOption: Equatable, Identifiable, Sendable {
      let route: BusRoute
      let directionName: String
      let nextStopName: String

      var id: BusRoute.ID { route.id }
    }

    let busStop: BusStop
    var routeOptions: [RouteOption]
    var selectedRouteIDs: Set<BusRoute.ID>
    var isLoading = false
    var errorMessage: String?
    var hasLoadedRoutes = false

    init(
      boardingPoint: BoardingPoint,
      busStop: BusStop,
      availableRoutes: [RouteOption] = []
    ) {
      self.busStop = busStop
      let selectedRoutes = boardingPoint.routes[busStop] ?? []
      var optionsByID = Dictionary(
        uniqueKeysWithValues: availableRoutes.map { ($0.id, $0) }
      )
      for route in selectedRoutes where optionsByID[route.id] == nil {
        optionsByID[route.id] = RouteOption(
          route: route,
          directionName: "",
          nextStopName: ""
        )
      }
      self.routeOptions = Self.sortedOptions(optionsByID.values)
      self.selectedRouteIDs = Set(selectedRoutes.map(\.id))
    }

    var allRoutesAreSelected: Bool {
      !routeOptions.isEmpty && routeOptions.allSatisfy { selectedRouteIDs.contains($0.id) }
    }

    private static func sortedOptions<S: Sequence>(_ options: S) -> [RouteOption]
    where S.Element == RouteOption {
      options.sorted {
        let comparison = $0.route.number.localizedStandardCompare($1.route.number)
        if comparison == .orderedSame {
          return $0.route.id < $1.route.id
        }
        return comparison == .orderedAscending
      }
    }
  }

  enum Action: Equatable {
    enum RoutesResponse: Equatable {
      case success([State.RouteOption])
      case failure(String)
    }

    case task
    case retryButtonTapped
    case routesResponse(RoutesResponse)
    case routeTapped(BusRoute.ID)
    case selectAllButtonTapped
    case doneButtonTapped
    case delegate(Delegate)

    enum Delegate: Equatable {
      case selectionCompleted(BusStop, Set<BusRoute>)
    }
  }

  @Dependency(\.busArrivalAPIClient) var busArrivalAPIClient
  @Dependency(\.seoulBusRouteAPIClient) var seoulBusRouteAPIClient

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .task:
        guard !state.isLoading, !state.hasLoadedRoutes else {
          return .none
        }
        state.isLoading = true
        state.errorMessage = nil

        let stationID = state.busStop.id
        let existingOptions = state.routeOptions
        let fetchGyeonggiArrivals = busArrivalAPIClient.fetchArrivals
        let fetchSeoulRoutes = seoulBusRouteAPIClient.fetchRoutesByStation
        return .run { send in
          async let gyeonggiArrivals = try? fetchGyeonggiArrivals(stationID)
          async let seoulRoutes = try? fetchSeoulRoutes(stationID)
          let (gyeonggi, seoul) = await (gyeonggiArrivals, seoulRoutes)

          guard gyeonggi != nil || seoul != nil else {
            await send(.routesResponse(.failure("노선 목록을 불러오지 못했습니다.")))
            return
          }

          let routeOptions = Self.routeOptions(
            existingOptions: existingOptions,
            gyeonggiArrivals: gyeonggi ?? [],
            seoulRoutes: seoul ?? []
          )
          guard !routeOptions.isEmpty || (gyeonggi != nil && seoul != nil) else {
            await send(.routesResponse(.failure("노선 목록을 불러오지 못했습니다.")))
            return
          }
          await send(.routesResponse(.success(routeOptions)))
        }

      case .retryButtonTapped:
        state.hasLoadedRoutes = false
        return .send(.task)

      case let .routesResponse(.success(routeOptions)):
        state.isLoading = false
        state.hasLoadedRoutes = true
        state.errorMessage = nil
        state.routeOptions = routeOptions
        return .none

      case let .routesResponse(.failure(message)):
        state.isLoading = false
        state.errorMessage = message
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
            .map(\.route)
        )
        return .send(.delegate(.selectionCompleted(state.busStop, selectedRoutes)))

      case .delegate:
        return .none
      }
    }
  }

  private static func routeOptions(
    existingOptions: [State.RouteOption],
    gyeonggiArrivals: [BusArrival],
    seoulRoutes: [BusRoute]
  ) -> [State.RouteOption] {
    var optionsByID = Dictionary(uniqueKeysWithValues: existingOptions.map { ($0.id, $0) })

    for arrival in gyeonggiArrivals {
      optionsByID[arrival.route.id] = State.RouteOption(
        route: arrival.route,
        directionName: arrival.destinationName.trimmingCharacters(in: .whitespacesAndNewlines),
        nextStopName: ""
      )
    }

    for route in seoulRoutes where optionsByID[route.id] == nil {
      optionsByID[route.id] = State.RouteOption(
        route: route,
        directionName: "",
        nextStopName: ""
      )
    }

    return optionsByID.values.sorted {
      let comparison = $0.route.number.localizedStandardCompare($1.route.number)
      if comparison == .orderedSame {
        return $0.route.id < $1.route.id
      }
      return comparison == .orderedAscending
    }
  }
}
