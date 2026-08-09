public protocol BusRouteRepository: Sendable {
  func fetchRoutes(at busStop: BusStop) async throws -> [BusRoute]
}
