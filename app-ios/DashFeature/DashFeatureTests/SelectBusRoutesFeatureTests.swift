import ComposableArchitecture
import DashDomain
import Testing
@testable import DashFeature

@MainActor
@Test func selectBusRoutesLoadsRoutesForBusStop() async {
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
    $0.routeOptions = [.route13]
  }
}

@MainActor
@Test func selectBusRoutesLoadsSeoulRoutesUsingARSID() async {
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
    $0.routeOptions = [.route662]
  }
}
