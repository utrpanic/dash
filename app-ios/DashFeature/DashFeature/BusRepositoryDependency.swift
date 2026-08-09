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

extension DependencyValues {
  var busArrivalRepository: any BusArrivalRepository {
    get { self[BusArrivalRepositoryKey.self] }
    set { self[BusArrivalRepositoryKey.self] = newValue }
  }

  var busRouteRepository: any BusRouteRepository {
    get { self[BusRouteRepositoryKey.self] }
    set { self[BusRouteRepositoryKey.self] = newValue }
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
