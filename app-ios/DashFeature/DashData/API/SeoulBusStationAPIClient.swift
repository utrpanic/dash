import DashDomain

public struct SeoulBusStationAPIService: Sendable {
  private let dataGoKrServiceKey: String

  public static let liveValue = Self(dataGoKrServiceKey: DashDataServiceKey.dataGoKrServiceKey)

  public init(dataGoKrServiceKey: String) {
    self.dataGoKrServiceKey = dataGoKrServiceKey
  }

  public func fetchRoutes(_ arsID: String) async throws -> [SeoulBusRouteAtStationDTO] {
    let response = try await SeoulBusAPITransport.fetch(
      path: "/api/rest/stationinfo/getRouteByStation",
      parameters: [
        ("serviceKey", try serviceKey()),
        ("arsId", arsID),
      ]
    )

    return try response.items.map { try SeoulBusRouteAtStationDTO(fields: $0) }
  }

  public func searchStops(matching query: String) async throws -> [BusStop] {
    let response = try await SeoulBusAPITransport.fetch(
      path: "/api/rest/stationinfo/getStationByName",
      parameters: [
        ("serviceKey", try serviceKey()),
        ("stSrch", query),
      ]
    )
    return try response.items.map { try SeoulBusStopDTO(fields: $0).toDomain() }
  }

  public func fetchNearbyStops(latitude: Double, longitude: Double) async throws -> [BusStop] {
    let response = try await SeoulBusAPITransport.fetch(
      path: "/api/rest/stationinfo/getStationByPos",
      parameters: [
        ("serviceKey", try serviceKey()),
        ("tmX", String(longitude)),
        ("tmY", String(latitude)),
        ("radius", "1000"),
      ]
    )
    return try response.items.map { try SeoulBusStopDTO(fields: $0).toDomain() }
  }
}

private extension SeoulBusStationAPIService {
  func serviceKey() throws -> String {
    let serviceKey = dataGoKrServiceKey.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !serviceKey.isEmpty else {
      throw SeoulBusAPIError.missingServiceKey
    }

    return serviceKey
  }
}
