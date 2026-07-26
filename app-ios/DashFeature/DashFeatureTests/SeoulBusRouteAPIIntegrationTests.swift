import ComposableArchitecture
import Testing
@testable import DashFeature

private let seoulSampleRoute = BusRoute.seoul_662

@Test func searchSeoulBusRoutesThroughFeature() async throws {
  let routes = try await SeoulBusRouteAPIClient.liveValue.searchRoutes(seoulSampleRoute.number)
  let route = try #require(routes.first { $0.id == seoulSampleRoute.id })

  #expect(route == seoulSampleRoute)
}

@Test func fetchSeoulBusRouteInfoThroughFeature() async throws {
  let routeInfo = try await SeoulBusRouteAPIClient.liveValue.fetchRouteInfo(seoulSampleRoute.id)

  #expect(routeInfo.route == seoulSampleRoute)
  #expect(routeInfo.regionName == "서울")
  #expect(!routeInfo.startStationName.isEmpty)
  #expect(!routeInfo.endStationName.isEmpty)
}

@Test func fetchSeoulBusRouteLineThroughFeature() async throws {
  let linePoints = try await SeoulBusRouteAPIClient.liveValue.fetchRouteLine(seoulSampleRoute.id)
  let firstPoint = try #require(linePoints.first)

  #expect(firstPoint.sequence > 0)
  #expect(firstPoint.x > 0)
  #expect(firstPoint.y > 0)
}
