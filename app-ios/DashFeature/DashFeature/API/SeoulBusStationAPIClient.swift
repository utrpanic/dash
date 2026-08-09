import ComposableArchitecture
import DashDomain

public struct SeoulBusStationAPIClient: Sendable {
  public var fetchRoutes: @Sendable (String) async throws -> [BusRoute]

  public init(api: any SeoulBusStationAPI) {
    self.init(fetchRoutes: api.fetchRoutes)
  }

  public init(fetchRoutes: @escaping @Sendable (String) async throws -> [BusRoute]) {
    self.fetchRoutes = fetchRoutes
  }
}

extension SeoulBusStationAPIClient: DependencyKey {
  public static let liveValue = Self(fetchRoutes: { _ in [] })
  public static let testValue = Self(fetchRoutes: { _ in [] })
}

public extension DependencyValues {
  var seoulBusStationAPIClient: SeoulBusStationAPIClient {
    get { self[SeoulBusStationAPIClient.self] }
    set { self[SeoulBusStationAPIClient.self] = newValue }
  }
}
