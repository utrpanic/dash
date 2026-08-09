import DashDomain

public struct LiveBusRouteRepository: BusRouteRepository {
  private let gyeonggiAPI: GyeonggiBusStationAPIService
  private let seoulAPI: SeoulBusStationAPIService

  public static let liveValue = Self(
    gyeonggiAPI: .liveValue,
    seoulAPI: .liveValue
  )

  public init(
    gyeonggiAPI: GyeonggiBusStationAPIService,
    seoulAPI: SeoulBusStationAPIService
  ) {
    self.gyeonggiAPI = gyeonggiAPI
    self.seoulAPI = seoulAPI
  }

  public func fetchRoutes(at busStop: BusStop) async throws -> [BusRoute] {
    switch busStop.id {
    case let .gyeonggi(stopID):
      try await gyeonggiAPI.fetchRoutes(stopID).map { $0.toDomain() }
    case let .seoul(_, arsID):
      try await seoulAPI.fetchRoutes(arsID).map { $0.toDomain() }
    }
  }
}
