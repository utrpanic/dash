import ComposableArchitecture
import DashDomain
import Testing
@testable import DashFeature

@Suite struct SelectBusRoutesFeatureTests {
  @MainActor
  @Test func loadsRoutesForBusStop() async {
    let route = BusRoute.route13
    let store = TestStore(
      initialState: SelectBusRoutesFeature.State(
        boardingPoint: .suwonStation,
        busStop: .suwonStationExit7Outer
      )
    ) {
      SelectBusRoutesFeature()
    } withDependencies: {
      $0.busRouteRepository = BusRouteRepositoryStub { busStop in
        #expect(busStop == .suwonStationExit7Outer)
        return [route]
      }
    }

    await store.send(.task) {
      $0.isLoadingRoutes = true
    }
    await store.receive(.routeOptionsResponse(.success([route]))) {
      $0.isLoadingRoutes = false
    }
  }

  @MainActor
  @Test func loadsSeoulRoutesUsingARSID() async {
    let route = BusRoute.route662
    let store = TestStore(
      initialState: SelectBusRoutesFeature.State(
        boardingPoint: .theHyundaiSeoul,
        busStop: .theHyundaiSeoul
      )
    ) {
      SelectBusRoutesFeature()
    } withDependencies: {
      $0.busRouteRepository = BusRouteRepositoryStub { busStop in
        #expect(busStop == .theHyundaiSeoul)
        return [route]
      }
    }

    await store.send(.task) {
      $0.isLoadingRoutes = true
    }
    await store.receive(.routeOptionsResponse(.success([route]))) {
      $0.isLoadingRoutes = false
    }
  }

  @MainActor
  @Test func togglesIndividualRoute() async {
    let route = BusRoute.route13
    let boardingPoint = BoardingPoint(
      id: "test",
      name: "테스트",
      routes: [:]
    )
    let store = TestStore(
      initialState: SelectBusRoutesFeature.State(
        boardingPoint: boardingPoint,
        busStop: .suwonStationExit7Outer,
        availableRoutes: [route]
      )
    ) {
      SelectBusRoutesFeature()
    }

    await store.send(.routeTapped(route.id)) {
      $0.selectedRouteIDs = [route.id]
    }
    await store.send(.routeTapped(route.id)) {
      $0.selectedRouteIDs = []
    }
  }

  @MainActor
  @Test func requiresSelectionToComplete() async {
    let route = BusRoute.route13
    let busStop = BusStop.suwonStationExit7Outer
    let boardingPoint = BoardingPoint(
      id: "test",
      name: "테스트",
      routes: [:]
    )
    let store = TestStore(
      initialState: SelectBusRoutesFeature.State(
        boardingPoint: boardingPoint,
        busStop: busStop,
        availableRoutes: [route]
      )
    ) {
      SelectBusRoutesFeature()
    }

    await store.send(.doneButtonTapped)
    await store.send(.routeTapped(route.id)) {
      $0.selectedRouteIDs = [route.id]
    }
    await store.send(.doneButtonTapped)
    await store.receive(.delegate(.selectionCompleted(busStop, [route])))
  }
}
