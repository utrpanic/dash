public protocol BusArrivalRepository: Sendable {
  func fetchArrivals(
    at busStop: BusStop,
    for routes: Set<BusRoute>
  ) async throws -> [BusArrival]
}
