public protocol BusStopRepository: Sendable {
  func searchStops(matching query: String) async throws -> [BusStop]
  func fetchNearbyStops(latitude: Double, longitude: Double) async throws -> [BusStop]
}
