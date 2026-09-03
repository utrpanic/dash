import DashDomain

public struct LiveBusStopRepository: BusStopRepository, Sendable {
  private let gyeonggiAPI: GyeonggiBusStationAPIService
  private let seoulAPI: SeoulBusStationAPIService

  public static let liveValue = Self(
    gyeonggiAPI: .liveValue,
    seoulAPI: .liveValue
  )

  public init(
    gyeonggiAPI: GyeonggiBusStationAPIService,
    seoulAPI: SeoulBusStationAPIService
  ) {
    self.gyeonggiAPI = gyeonggiAPI
    self.seoulAPI = seoulAPI
  }

  public func searchStops(matching query: String) async throws -> [BusStop] {
    let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !query.isEmpty else { return [] }
    async let gyeonggiResult = Self.capture { try await gyeonggiAPI.searchStops(matching: query) }
    async let seoulResult = Self.capture { try await seoulAPI.searchStops(matching: query) }
    return try await combined(gyeonggiResult, seoulResult)
  }

  public func fetchNearbyStops(latitude: Double, longitude: Double) async throws -> [BusStop] {
    guard Self.supportsNearbySearch(latitude: latitude, longitude: longitude) else {
      return []
    }
    async let gyeonggiResult = Self.capture {
      try await gyeonggiAPI.fetchNearbyStops(latitude: latitude, longitude: longitude)
    }
    async let seoulResult = Self.capture {
      try await seoulAPI.fetchNearbyStops(latitude: latitude, longitude: longitude)
    }
    return try await combined(gyeonggiResult, seoulResult)
  }

  private func unique(_ stops: [BusStop]) -> [BusStop] {
    var seen = Set<BusStop.ID>()
    return stops.filter { seen.insert($0.id).inserted }
  }

  private func combined(_ first: FetchResult, _ second: FetchResult) throws -> [BusStop] {
    let stops = [first, second].flatMap { result in
      if case let .success(stops) = result { return stops }
      return []
    }
    guard !stops.isEmpty || first.isSuccess || second.isSuccess else {
      throw BusStopRepositoryError.allRequestsFailed
    }
    return unique(stops)
  }

  private static func capture(
    _ operation: @escaping @Sendable () async throws -> [BusStop]
  ) async -> FetchResult {
    do {
      return .success(try await operation())
    } catch {
      return .failure
    }
  }

  private static func supportsNearbySearch(latitude: Double, longitude: Double) -> Bool {
    (36.8...38.4).contains(latitude) && (126.0...128.3).contains(longitude)
  }
}

public enum BusStopRepositoryError: Error, Equatable, Sendable {
  case allRequestsFailed
}

private enum FetchResult: Sendable {
  case success([BusStop])
  case failure

  var isSuccess: Bool {
    if case .success = self { return true }
    return false
  }
}
