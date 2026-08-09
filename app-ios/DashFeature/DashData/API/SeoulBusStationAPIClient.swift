import DashDomain

public struct SeoulBusStationAPIService: SeoulBusStationAPI {
  private let dataGoKrServiceKey: String

  public static let liveValue = Self(dataGoKrServiceKey: DashDataServiceKey.dataGoKrServiceKey)

  public init(dataGoKrServiceKey: String) {
    self.dataGoKrServiceKey = dataGoKrServiceKey
  }

  public func fetchRoutes(_ arsID: String) async throws -> [BusRoute] {
    let response = try await SeoulBusAPITransport.fetch(
      path: "/api/rest/stationinfo/getRouteByStation",
      parameters: [
        ("serviceKey", try serviceKey()),
        ("arsId", arsID),
      ]
    )

    return try response.items.map { try SeoulBusRouteAtStationDTO(fields: $0).toDomain() }
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
