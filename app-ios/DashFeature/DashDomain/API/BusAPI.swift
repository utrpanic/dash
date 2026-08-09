public protocol GyeonggiBusArrivalAPI: Sendable {
  func fetchArrival(
    _ stationId: Int,
    _ routeId: Int,
    _ stationOrder: Int
  ) async throws -> BusArrival
  func fetchArrivals(_ stationId: Int) async throws -> [BusArrival]
}

public protocol GyeonggiBusStationAPI: Sendable {
  func fetchRoutes(_ stationId: Int) async throws -> [BusRoute]
}

public protocol SeoulBusArrivalAPI: Sendable {
  func fetchArrival(
    _ stationId: Int,
    _ routeId: Int,
    _ stationOrder: Int
  ) async throws -> BusArrival
  func fetchArrivalsByRoute(_ routeId: Int) async throws -> [BusArrival]
  func fetchLowFloorArrival(
    _ stationId: Int,
    _ routeId: Int,
    _ stationOrder: Int
  ) async throws -> BusArrival
  func fetchLowFloorArrivals(_ stationId: Int) async throws -> [BusArrival]
}

public protocol SeoulBusStationAPI: Sendable {
  func fetchRoutes(_ arsID: String) async throws -> [BusRoute]
}
