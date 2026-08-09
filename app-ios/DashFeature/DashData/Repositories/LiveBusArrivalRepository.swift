import DashDomain

public struct LiveBusArrivalRepository: BusArrivalRepository {
  private let gyeonggiAPI: GyeonggiBusArrivalAPIService
  private let seoulAPI: SeoulBusArrivalAPIService

  public static let liveValue = Self(
    gyeonggiAPI: .liveValue,
    seoulAPI: .liveValue
  )

  public init(
    gyeonggiAPI: GyeonggiBusArrivalAPIService,
    seoulAPI: SeoulBusArrivalAPIService
  ) {
    self.gyeonggiAPI = gyeonggiAPI
    self.seoulAPI = seoulAPI
  }

  public func fetchArrivals(
    at busStop: BusStop,
    for routes: Set<BusRoute>
  ) async throws -> [BusArrival] {
    guard !routes.isEmpty else { return [] }

    let routeIDs = Set(routes.map(\.id))
    switch busStop.id {
    case let .gyeonggi(stationID):
      return try await gyeonggiAPI.fetchArrivals(stationID)
        .map { $0.toDomain() }
        .filter { routeIDs.contains($0.route.id) }

    case let .seoul(stationID, _):
      var arrivals: [BusArrival] = []
      for route in routes {
        let routeArrivals = try await seoulAPI.fetchArrivalsByRoute(route.id)
        arrivals.append(
          contentsOf: routeArrivals
            .map { $0.toDomain() }
            .filter { $0.stationId == stationID }
        )
      }
      return arrivals
    }
  }
}
