import Testing
import DashData
@testable import DashFeature

private let initialSeoulStops: [BusStop] = [
  .yeongdeungpoStation,
  .theHyundaiSeoul,
]

@Suite struct InitialSeoulBusStopIntegrationTests {
  @Test func initialSeoulStopsUseVerifiedARSIDs() async throws {
    let repository = LiveBusRouteRepository.liveValue
    for stop in initialSeoulStops {
      let routes = try await repository.fetchRoutes(at: stop)

      #expect(routes.contains(.route662))
    }
  }
}
