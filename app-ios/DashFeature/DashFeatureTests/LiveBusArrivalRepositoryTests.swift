import DashDomain
import Testing
@testable import DashData

private enum LiveRepositoryTestError: Error {
  case unavailable
}

@Test func seoulRepositoryKeepsSuccessfulRoutesWhenAnotherRouteFails() async throws {
  let arrival = try SeoulBusArrivalDTO(
    fields: [
      "stId": String(BusStop.theHyundaiSeoul.id.stopID),
      "busRouteId": String(BusRoute.route662.id),
      "busRouteAbrv": BusRoute.route662.number,
      "staOrd": "1",
      "exps1": "120",
    ]
  )

  let arrivals = try await LiveBusArrivalRepository.fetchSeoulArrivals(
    stopID: BusStop.theHyundaiSeoul.id.stopID,
    routes: [.route662, .route6628]
  ) { routeID in
    if routeID == BusRoute.route662.id { return [arrival] }
    throw LiveRepositoryTestError.unavailable
  }

  #expect(arrivals == [arrival.toDomain()])
}
