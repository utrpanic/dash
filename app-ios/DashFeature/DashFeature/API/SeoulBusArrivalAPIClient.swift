import ComposableArchitecture

public struct SeoulBusArrivalAPIClient: Sendable {
  public var fetchArrival: @Sendable (
    _ stationId: Int,
    _ routeId: Int,
    _ stationOrder: Int
  ) async throws -> BusArrival
  public var fetchArrivalsByRoute: @Sendable (_ routeId: Int) async throws -> [BusArrival]
  public var fetchLowFloorArrival: @Sendable (
    _ stationId: Int,
    _ routeId: Int,
    _ stationOrder: Int
  ) async throws -> BusArrival
  public var fetchLowFloorArrivals: @Sendable (_ stationId: Int) async throws -> [BusArrival]

  public init(
    fetchArrival: @escaping @Sendable (
      _ stationId: Int,
      _ routeId: Int,
      _ stationOrder: Int
    ) async throws -> BusArrival,
    fetchArrivalsByRoute: @escaping @Sendable (_ routeId: Int) async throws -> [BusArrival],
    fetchLowFloorArrival: @escaping @Sendable (
      _ stationId: Int,
      _ routeId: Int,
      _ stationOrder: Int
    ) async throws -> BusArrival,
    fetchLowFloorArrivals: @escaping @Sendable (_ stationId: Int) async throws -> [BusArrival]
  ) {
    self.fetchArrival = fetchArrival
    self.fetchArrivalsByRoute = fetchArrivalsByRoute
    self.fetchLowFloorArrival = fetchLowFloorArrival
    self.fetchLowFloorArrivals = fetchLowFloorArrivals
  }
}

extension SeoulBusArrivalAPIClient: DependencyKey {
  public static let liveValue = SeoulBusArrivalAPIClient(
    fetchArrival: { stationId, routeId, stationOrder in
      try await fetchArrival(
        path: "/api/rest/arrive/getArrInfoByRoute",
        stationId: stationId,
        routeId: routeId,
        stationOrder: stationOrder
      )
    },
    fetchArrivalsByRoute: { routeId in
      let response = try await SeoulBusAPITransport.fetch(
        path: "/api/rest/arrive/getArrInfoByRouteAll",
        parameters: [
          ("serviceKey", try SeoulBusAPITransport.serviceKey()),
          ("busRouteId", String(routeId)),
        ]
      )

      return try response.items.map { try SeoulBusArrivalDTO(fields: $0).toDomain() }
    },
    fetchLowFloorArrival: { stationId, routeId, stationOrder in
      try await fetchArrival(
        path: "/api/rest/arrive/getLowArrInfoByRoute",
        stationId: stationId,
        routeId: routeId,
        stationOrder: stationOrder
      )
    },
    fetchLowFloorArrivals: { stationId in
      let response = try await SeoulBusAPITransport.fetch(
        path: "/api/rest/arrive/getLowArrInfoByStId",
        parameters: [
          ("serviceKey", try SeoulBusAPITransport.serviceKey()),
          ("stId", String(stationId)),
        ]
      )

      return try response.items.map { try SeoulBusArrivalDTO(fields: $0).toDomain() }
    }
  )

  public static let testValue = Self(
    fetchArrival: { stationId, routeId, stationOrder in
      emptyArrival(stationId: stationId, routeId: routeId, stationOrder: stationOrder)
    },
    fetchArrivalsByRoute: { _ in [] },
    fetchLowFloorArrival: { stationId, routeId, stationOrder in
      emptyArrival(stationId: stationId, routeId: routeId, stationOrder: stationOrder)
    },
    fetchLowFloorArrivals: { _ in [] }
  )
}

extension DependencyValues {
  public var seoulBusArrivalAPIClient: SeoulBusArrivalAPIClient {
    get { self[SeoulBusArrivalAPIClient.self] }
    set { self[SeoulBusArrivalAPIClient.self] = newValue }
  }
}

private extension SeoulBusArrivalAPIClient {
  static func fetchArrival(
    path: String,
    stationId: Int,
    routeId: Int,
    stationOrder: Int
  ) async throws -> BusArrival {
    let response = try await SeoulBusAPITransport.fetch(
      path: path,
      parameters: [
        ("serviceKey", try SeoulBusAPITransport.serviceKey()),
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

  static func emptyArrival(stationId: Int, routeId: Int, stationOrder: Int) -> BusArrival {
    BusArrival(
      stationId: stationId,
      route: BusRoute(id: routeId, number: "", region: .seoul),
      stationOrder: stationOrder,
      destinationName: "",
      operationState: "",
      firstPrediction: nil,
      secondPrediction: nil
    )
  }
}
