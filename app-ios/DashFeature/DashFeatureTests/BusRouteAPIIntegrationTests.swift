import ComposableArchitecture
import Testing
@testable import DashFeature

@Test func searchBusRoutesThroughFeature() async throws {
  let routes = try await BusRouteAPIClient.liveValue.searchRoutes("13")
  let firstRoute = try #require(routes.first)

  #expect(firstRoute.id > 0)
  #expect(!firstRoute.number.isEmpty)
}

@Test func fetchBusRouteInfoThroughFeature() async throws {
  let routeInfo = try await BusRouteAPIClient.liveValue.fetchRouteInfo(234000130)

  #expect(routeInfo.route.id == 234000130)
  #expect(!routeInfo.route.number.isEmpty)
  #expect(!routeInfo.startStationName.isEmpty)
  #expect(!routeInfo.endStationName.isEmpty)
}

@Test func fetchBusRouteLineThroughFeature() async throws {
  let linePoints = try await BusRouteAPIClient.liveValue.fetchRouteLine(234000130)
  let firstPoint = try #require(linePoints.first)

  #expect(!linePoints.isEmpty)
  #expect(firstPoint.sequence > 0)
  #expect(firstPoint.x > 0)
  #expect(firstPoint.y > 0)
}

@Test func fetchKnownSuwonRouteConstantsThroughFeature() async throws {
  let routes: [BusRoute] = [
    .gyeonggi_9,
    .gyeonggi_9_1,
    .gyeonggi_13,
    .gyeonggi_13_1,
    .gyeonggi_13_4,
    .gyeonggi_13_5,
    .gyeonggi_15_1,
  ]

  for route in routes {
    let routeInfo = try await BusRouteAPIClient.liveValue.fetchRouteInfo(route.id)

    #expect(routeInfo.route == route)
    #expect(routeInfo.regionName.contains("수원"))
  }
}

@MainActor
@Test func reducerStoresSearchedBusRoutes() async {
  let store = TestStore(initialState: DashFeatureState()) {
    DashFeature()
  } withDependencies: {
    $0.busRouteAPIClient.searchRoutes = { _ in
      [
        BusRoute(id: 234000130, number: "1303", region: .gyeonggi)
      ]
    }
  }

  await store.send(.busRouteSearchRequested(keyword: "13")) {
    $0.busRouteSearchKeyword = "13"
    $0.isSearchingBusRoutes = true
    $0.busRouteSearchErrorMessage = nil
  }

  await store.receive(
    .busRouteSearchResponse(
      .success([BusRoute(id: 234000130, number: "1303", region: .gyeonggi)])
    )
  ) {
    $0.isSearchingBusRoutes = false
    $0.busRouteSearchResults = [
      BusRoute(id: 234000130, number: "1303", region: .gyeonggi)
    ]
    $0.busRouteSearchErrorMessage = nil
  }
}
