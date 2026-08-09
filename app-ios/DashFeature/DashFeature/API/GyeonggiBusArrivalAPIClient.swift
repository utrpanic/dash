import ComposableArchitecture
import DashDomain

public struct GyeonggiBusArrivalAPIClient: Sendable {
  public var fetchArrival: @Sendable (Int, Int, Int) async throws -> BusArrival
  public var fetchArrivals: @Sendable (Int) async throws -> [BusArrival]

  public init(api: any GyeonggiBusArrivalAPI) {
    self.init(
      fetchArrival: api.fetchArrival,
      fetchArrivals: api.fetchArrivals
    )
  }

  public init(
    fetchArrival: @escaping @Sendable (Int, Int, Int) async throws -> BusArrival,
    fetchArrivals: @escaping @Sendable (Int) async throws -> [BusArrival]
  ) {
    self.fetchArrival = fetchArrival
    self.fetchArrivals = fetchArrivals
  }
}

extension GyeonggiBusArrivalAPIClient: DependencyKey {
  public static let liveValue = Self(
    fetchArrival: { _, _, _ in
      BusArrival(
        stationId: 0,
        route: BusRoute(id: 0, number: ""),
        stationOrder: 0,
        operationState: "",
        firstPrediction: nil,
        secondPrediction: nil
      )
    },
    fetchArrivals: { _ in [] }
  )
  public static let testValue = Self(
    fetchArrival: { _, _, _ in
      BusArrival(
        stationId: 0,
        route: BusRoute(id: 0, number: ""),
        stationOrder: 0,
        operationState: "",
        firstPrediction: nil,
        secondPrediction: nil
      )
    },
    fetchArrivals: { _ in [] }
  )
}

public extension DependencyValues {
  var gyeonggiBusArrivalAPIClient: GyeonggiBusArrivalAPIClient {
    get { self[GyeonggiBusArrivalAPIClient.self] }
    set { self[GyeonggiBusArrivalAPIClient.self] = newValue }
  }
}
