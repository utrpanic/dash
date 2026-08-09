import ComposableArchitecture
import DashDomain

public struct GyeonggiBusStationAPIClient: Sendable {
  public var fetchRoutes: @Sendable (Int) async throws -> [BusRoute]

  public init(api: any GyeonggiBusStationAPI) {
    self.init(fetchRoutes: api.fetchRoutes)
  }

  public init(fetchRoutes: @escaping @Sendable (Int) async throws -> [BusRoute]) {
    self.fetchRoutes = fetchRoutes
  }
}

extension GyeonggiBusStationAPIClient: DependencyKey {
  public static let liveValue = Self(fetchRoutes: { _ in [] })
  public static let testValue = Self(fetchRoutes: { _ in [] })
}

public extension DependencyValues {
  var gyeonggiBusStationAPIClient: GyeonggiBusStationAPIClient {
    get { self[GyeonggiBusStationAPIClient.self] }
    set { self[GyeonggiBusStationAPIClient.self] = newValue }
  }
}
