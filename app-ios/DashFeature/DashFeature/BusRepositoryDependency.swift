import ComposableArchitecture
import DashDomain

private enum BusArrivalRepositoryKey: DependencyKey {
  static let liveValue: any BusArrivalRepository = EmptyBusArrivalRepository()
  static let testValue: any BusArrivalRepository = EmptyBusArrivalRepository()
}

private enum BusRouteRepositoryKey: DependencyKey {
  static let liveValue: any BusRouteRepository = EmptyBusRouteRepository()
  static let testValue: any BusRouteRepository = EmptyBusRouteRepository()
}

private enum BusStopRepositoryKey: DependencyKey {
  static let liveValue: any BusStopRepository = EmptyBusStopRepository()
  static let testValue: any BusStopRepository = EmptyBusStopRepository()
}

extension DependencyValues {
  var busArrivalRepository: any BusArrivalRepository {
    get { self[BusArrivalRepositoryKey.self] }
    set { self[BusArrivalRepositoryKey.self] = newValue }
  }

  var busRouteRepository: any BusRouteRepository {
    get { self[BusRouteRepositoryKey.self] }
    set { self[BusRouteRepositoryKey.self] = newValue }
  }

  var busStopRepository: any BusStopRepository {
    get { self[BusStopRepositoryKey.self] }
    set { self[BusStopRepositoryKey.self] = newValue }
  }
}

struct EmptyBusArrivalRepository: BusArrivalRepository {
  func fetchArrivals(
    at busStop: BusStop,
    for routes: Set<BusRoute>
  ) async throws -> [BusArrival] {
    []
  }
}

struct EmptyBusRouteRepository: BusRouteRepository {
  func fetchRoutes(at busStop: BusStop) async throws -> [BusRoute] {
    []
  }
}

struct EmptyBusStopRepository: BusStopRepository {
  func searchStops(matching query: String) async throws -> [BusStop] { [] }
  func fetchNearbyStops(latitude: Double, longitude: Double) async throws -> [BusStop] { [] }
}
