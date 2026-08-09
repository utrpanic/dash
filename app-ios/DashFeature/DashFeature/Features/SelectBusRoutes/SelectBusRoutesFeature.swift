import ComposableArchitecture
import DashDomain
import Foundation

@Reducer
struct SelectBusRoutesFeature {
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

    init(
      boardingPoint: BoardingPoint,
      busStop: BusStop,
      availableRoutes: [RouteOption] = []
    ) {
      self.busStop = busStop

      let selectedRoutes = boardingPoint.routes[busStop] ?? []
      var optionsByID: [BusRoute.ID: RouteOption] = [:]
      for option in availableRoutes {
        optionsByID[option.id] = option
      }
      for route in selectedRoutes where optionsByID[route.id] == nil {
        optionsByID[route.id] = RouteOption(
          route: route,
          directionName: "",
          nextStopName: ""
        )
      }

      self.routeOptions = optionsByID.values.sorted {
        let comparison = $0.route.number.localizedStandardCompare($1.route.number)
        if comparison == .orderedSame {
          return $0.route.id < $1.route.id
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
    case routeTapped(BusRoute.ID)
    case selectAllButtonTapped
    case doneButtonTapped
    case delegate(Delegate)

    enum Delegate: Equatable {
      case selectionCompleted(BusStop, Set<BusRoute>)
    }
  }

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
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
}
