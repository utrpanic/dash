import ComposableArchitecture

public struct SeoulBusRouteAPIClient: Sendable {
  public var fetchRouteInfo: @Sendable (_ routeId: Int) async throws -> BusRouteInfo
  public var fetchRouteLine: @Sendable (_ routeId: Int) async throws -> [BusRouteLinePoint]
  public var searchRoutes: @Sendable (_ keyword: String) async throws -> [BusRoute]

  public init(
    fetchRouteInfo: @escaping @Sendable (_ routeId: Int) async throws -> BusRouteInfo,
    fetchRouteLine: @escaping @Sendable (_ routeId: Int) async throws -> [BusRouteLinePoint],
    searchRoutes: @escaping @Sendable (_ keyword: String) async throws -> [BusRoute]
  ) {
    self.fetchRouteInfo = fetchRouteInfo
    self.fetchRouteLine = fetchRouteLine
    self.searchRoutes = searchRoutes
  }
}

extension SeoulBusRouteAPIClient: DependencyKey {
  public static let liveValue = Self(
    fetchRouteInfo: { routeId in
      let response = try await SeoulBusAPITransport.fetch(
        path: "/api/rest/busRouteInfo/getRouteInfo",
        parameters: [
          ("serviceKey", try SeoulBusAPITransport.serviceKey()),
          ("busRouteId", String(routeId)),
        ]
      )
      guard let item = response.items.first else {
        throw SeoulBusAPIError.malformedResponse("Missing route info item.")
      }

      return try SeoulBusRouteInfoDTO(fields: item).toDomain()
    },
    fetchRouteLine: { routeId in
      let response = try await SeoulBusAPITransport.fetch(
        path: "/api/rest/busRouteInfo/getRoutePath",
        parameters: [
          ("serviceKey", try SeoulBusAPITransport.serviceKey()),
          ("busRouteId", String(routeId)),
        ]
      )

      return try response.items.map { try SeoulBusRouteLineDTO(fields: $0).toDomain() }
    },
    searchRoutes: { keyword in
      let response = try await SeoulBusAPITransport.fetch(
        path: "/api/rest/busRouteInfo/getBusRouteList",
        parameters: [
          ("serviceKey", try SeoulBusAPITransport.serviceKey()),
          ("strSrch", keyword),
        ]
      )

      return try response.items.map { try SeoulBusRouteDTO(fields: $0).toDomain() }
    }
  )

  public static let testValue = Self(
    fetchRouteInfo: { routeId in
      BusRouteInfo(
        route: BusRoute(id: routeId, number: "", region: .seoul),
        routeTypeName: "",
        regionName: "서울",
        companyName: "",
        startStationName: "",
        endStationName: ""
      )
    },
    fetchRouteLine: { _ in [] },
    searchRoutes: { _ in [] }
  )
}

extension DependencyValues {
  public var seoulBusRouteAPIClient: SeoulBusRouteAPIClient {
    get { self[SeoulBusRouteAPIClient.self] }
    set { self[SeoulBusRouteAPIClient.self] = newValue }
  }
}
