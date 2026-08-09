import DashDomain

public struct SeoulBusArrivalAPIService: SeoulBusArrivalAPI {
  private let dataGoKrServiceKey: String

  public static let liveValue = Self(dataGoKrServiceKey: DashDataServiceKey.dataGoKrServiceKey)

  public init(dataGoKrServiceKey: String) {
    self.dataGoKrServiceKey = dataGoKrServiceKey
  }

  public func fetchArrival(
    _ stationId: Int,
    _ routeId: Int,
    _ stationOrder: Int
  ) async throws -> BusArrival {
    try await fetchArrival(
      path: "/api/rest/arrive/getArrInfoByRoute",
      stationId: stationId,
      routeId: routeId,
      stationOrder: stationOrder
    )
  }

  public func fetchArrivalsByRoute(_ routeId: Int) async throws -> [BusArrival] {
    let response = try await SeoulBusAPITransport.fetch(
      path: "/api/rest/arrive/getArrInfoByRouteAll",
      parameters: [
        ("serviceKey", try serviceKey()),
        ("busRouteId", String(routeId)),
      ]
    )

    return try response.items.map { try SeoulBusArrivalDTO(fields: $0).toDomain() }
  }

  public func fetchLowFloorArrival(
    _ stationId: Int,
    _ routeId: Int,
    _ stationOrder: Int
  ) async throws -> BusArrival {
    try await fetchArrival(
      path: "/api/rest/arrive/getLowArrInfoByRoute",
      stationId: stationId,
      routeId: routeId,
      stationOrder: stationOrder
    )
  }

  public func fetchLowFloorArrivals(_ stationId: Int) async throws -> [BusArrival] {
    let response = try await SeoulBusAPITransport.fetch(
      path: "/api/rest/arrive/getLowArrInfoByStId",
      parameters: [
        ("serviceKey", try serviceKey()),
        ("stId", String(stationId)),
      ]
    )

    return try response.items.map { try SeoulBusArrivalDTO(fields: $0).toDomain() }
  }
}

private extension SeoulBusArrivalAPIService {
  func fetchArrival(
    path: String,
    stationId: Int,
    routeId: Int,
    stationOrder: Int
  ) async throws -> BusArrival {
    let response = try await SeoulBusAPITransport.fetch(
      path: path,
      parameters: [
        ("serviceKey", try serviceKey()),
        ("stId", String(stationId)),
        ("busRouteId", String(routeId)),
        ("ord", String(stationOrder)),
      ]
    )
    guard let item = response.items.first else {
      throw SeoulBusAPIError.malformedResponse("Missing arrival item.")
    }

    return try SeoulBusArrivalDTO(fields: item).toDomain()
  }

  func serviceKey() throws -> String {
    let serviceKey = dataGoKrServiceKey.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !serviceKey.isEmpty else {
      throw SeoulBusAPIError.missingServiceKey
    }

    return serviceKey
  }
}
