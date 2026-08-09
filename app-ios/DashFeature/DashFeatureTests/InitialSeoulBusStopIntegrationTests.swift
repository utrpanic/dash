import Testing
import DashData
@testable import DashFeature

private let initialSeoulStops: [BusStop] = [
  .yeongdeungpoStation,
  .theHyundaiSeoul,
]

@Suite struct InitialSeoulBusStopIntegrationTests {
  @Test func initialSeoulStopsUseVerifiedARSIDs() async throws {
    let api = SeoulBusStationAPIService.liveValue
    for stop in initialSeoulStops {
      let arsID = try seoulARSID(for: stop)
      let routes = try await api.fetchRoutes(arsID)

      #expect(routes.contains(.route662))
    }
  }
}

private func seoulARSID(for stop: BusStop) throws -> String {
  guard case let .seoul(_, arsID) = stop.id else {
    throw InitialSeoulBusStopIntegrationTestError.notSeoulStop
  }
  return arsID
}

private enum InitialSeoulBusStopIntegrationTestError: Error {
  case notSeoulStop
}
