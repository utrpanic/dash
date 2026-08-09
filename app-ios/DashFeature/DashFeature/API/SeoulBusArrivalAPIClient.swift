import ComposableArchitecture
import DashDomain

public struct SeoulBusArrivalAPIClient: Sendable {
  public var fetchArrival: @Sendable (Int, Int, Int) async throws -> BusArrival
  public var fetchArrivalsByRoute: @Sendable (Int) async throws -> [BusArrival]
  public var fetchLowFloorArrival: @Sendable (Int, Int, Int) async throws -> BusArrival
  public var fetchLowFloorArrivals: @Sendable (Int) async throws -> [BusArrival]

  public init(api: any SeoulBusArrivalAPI) {
    self.init(
      fetchArrival: api.fetchArrival,
      fetchArrivalsByRoute: api.fetchArrivalsByRoute,
      fetchLowFloorArrival: api.fetchLowFloorArrival,
      fetchLowFloorArrivals: api.fetchLowFloorArrivals
    )
  }

  public init(
    fetchArrival: @escaping @Sendable (Int, Int, Int) async throws -> BusArrival,
    fetchArrivalsByRoute: @escaping @Sendable (Int) async throws -> [BusArrival],
    fetchLowFloorArrival: @escaping @Sendable (Int, Int, Int) async throws -> BusArrival,
    fetchLowFloorArrivals: @escaping @Sendable (Int) async throws -> [BusArrival]
  ) {
    self.fetchArrival = fetchArrival
    self.fetchArrivalsByRoute = fetchArrivalsByRoute
    self.fetchLowFloorArrival = fetchLowFloorArrival
    self.fetchLowFloorArrivals = fetchLowFloorArrivals
  }
}

extension SeoulBusArrivalAPIClient: DependencyKey {
  public static let liveValue = Self(
    fetchArrival: { stationId, routeId, stationOrder in
      Self.emptyArrival(stationId: stationId, routeId: routeId, stationOrder: stationOrder)
    },
    fetchArrivalsByRoute: { _ in [] },
    fetchLowFloorArrival: { stationId, routeId, stationOrder in
      Self.emptyArrival(stationId: stationId, routeId: routeId, stationOrder: stationOrder)
    },
    fetchLowFloorArrivals: { _ in [] }
  )
  public static let testValue = Self(
    fetchArrival: { stationId, routeId, stationOrder in
      Self.emptyArrival(stationId: stationId, routeId: routeId, stationOrder: stationOrder)
    },
    fetchArrivalsByRoute: { _ in [] },
    fetchLowFloorArrival: { stationId, routeId, stationOrder in
      Self.emptyArrival(stationId: stationId, routeId: routeId, stationOrder: stationOrder)
    },
    fetchLowFloorArrivals: { _ in [] }
  )

  private static func emptyArrival(stationId: Int, routeId: Int, stationOrder: Int) -> BusArrival {
    BusArrival(
      stationId: stationId,
      route: BusRoute(id: routeId, number: ""),
      stationOrder: stationOrder,
      operationState: "",
      firstPrediction: nil,
      secondPrediction: nil
    )
  }
}

public extension DependencyValues {
  var seoulBusArrivalAPIClient: SeoulBusArrivalAPIClient {
    get { self[SeoulBusArrivalAPIClient.self] }
    set { self[SeoulBusArrivalAPIClient.self] = newValue }
  }
}
