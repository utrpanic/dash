import DashDomain

public struct LiveBusArrivalRepository: BusArrivalRepository {
  private let gyeonggiAPI: GyeonggiBusArrivalAPIService
  private let seoulAPI: SeoulBusArrivalAPIService

  public static let liveValue = Self(
    gyeonggiAPI: .liveValue,
    seoulAPI: .liveValue
  )

  public init(
    gyeonggiAPI: GyeonggiBusArrivalAPIService,
    seoulAPI: SeoulBusArrivalAPIService
  ) {
    self.gyeonggiAPI = gyeonggiAPI
    self.seoulAPI = seoulAPI
  }

  public func fetchArrivals(
    at busStop: BusStop,
    for routes: Set<BusRoute>
  ) async throws -> [BusArrival] {
    guard !routes.isEmpty else { return [] }

    let routeIDs = Set(routes.map(\.id))
    switch busStop.id {
    case let .gyeonggi(stopID):
      return try await gyeonggiAPI.fetchArrivals(stopID)
        .map { $0.toDomain() }
        .filter { routeIDs.contains($0.route.id) }

    case let .seoul(stopID, _):
      return try await Self.fetchSeoulArrivals(
        stopID: stopID,
        routes: routes,
        fetchArrivalsByRoute: seoulAPI.fetchArrivalsByRoute
      )
    }
  }

  static func fetchSeoulArrivals(
    stopID: Int,
    routes: Set<BusRoute>,
    fetchArrivalsByRoute: @escaping @Sendable (Int) async throws -> [SeoulBusArrivalDTO]
  ) async throws -> [BusArrival] {
    let results = await withTaskGroup(of: RouteFetchResult.self) { group in
      for route in routes {
        group.addTask {
          do {
            let arrivals = try await fetchArrivalsByRoute(route.id)
              .map { $0.toDomain() }
              .filter { $0.stopID == stopID }
            return .success(arrivals)
          } catch {
            return .failure
          }
        }
      }

      var results: [RouteFetchResult] = []
      for await result in group {
        results.append(result)
      }
      return results
    }

    guard results.contains(where: \.isSuccess) else {
      throw LiveBusArrivalRepositoryError.unavailable
    }
    return results.flatMap(\.arrivals)
  }
}

private enum LiveBusArrivalRepositoryError: Error {
  case unavailable
}

private enum RouteFetchResult: Sendable {
  case success([BusArrival])
  case failure

  var isSuccess: Bool {
    if case .success = self { return true }
    return false
  }

  var arrivals: [BusArrival] {
    if case let .success(arrivals) = self { return arrivals }
    return []
  }
}
