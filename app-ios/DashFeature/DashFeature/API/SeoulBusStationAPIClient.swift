import ComposableArchitecture
import DashDomain

public struct SeoulBusStationAPIClient: Sendable {
  public var fetchRoutes: @Sendable (_ arsID: String) async throws -> [BusRoute]

  public init(
    fetchRoutes: @escaping @Sendable (_ arsID: String) async throws -> [BusRoute]
  ) {
    self.fetchRoutes = fetchRoutes
  }
}

extension SeoulBusStationAPIClient: DependencyKey {
  public static let liveValue = Self(
    fetchRoutes: { arsID in
      let response = try await SeoulBusAPITransport.fetch(
        path: "/api/rest/stationinfo/getRouteByStation",
        parameters: [
          ("serviceKey", try SeoulBusAPITransport.serviceKey()),
          ("arsId", arsID),
        ]
      )

      return try response.items.map { try SeoulBusRouteAtStationDTO(fields: $0).toDomain() }
    }
  )

  public static let testValue = Self(fetchRoutes: { _ in [] })
}

extension DependencyValues {
  public var seoulBusStationAPIClient: SeoulBusStationAPIClient {
    get { self[SeoulBusStationAPIClient.self] }
    set { self[SeoulBusStationAPIClient.self] = newValue }
  }
}
