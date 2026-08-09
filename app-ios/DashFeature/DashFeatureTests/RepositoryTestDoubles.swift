import DashDomain

struct BusArrivalRepositoryStub: BusArrivalRepository {
  let fetchArrivalsHandler: @Sendable (BusStop, Set<BusRoute>) async throws -> [BusArrival]

  init(
    fetchArrivals: @escaping @Sendable (BusStop, Set<BusRoute>) async throws -> [BusArrival]
  ) {
    self.fetchArrivalsHandler = fetchArrivals
  }

  func fetchArrivals(
    at busStop: BusStop,
    for routes: Set<BusRoute>
  ) async throws -> [BusArrival] {
    try await fetchArrivalsHandler(busStop, routes)
  }
}

struct BusRouteRepositoryStub: BusRouteRepository {
  let fetchRoutesHandler: @Sendable (BusStop) async throws -> [BusRoute]

  init(
    fetchRoutes: @escaping @Sendable (BusStop) async throws -> [BusRoute]
  ) {
    self.fetchRoutesHandler = fetchRoutes
  }

  func fetchRoutes(at busStop: BusStop) async throws -> [BusRoute] {
    try await fetchRoutesHandler(busStop)
  }
}
