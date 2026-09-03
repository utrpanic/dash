import DashData
import DashDomain
import Testing

@Test func searchGyeonggiBusStopsThroughAPI() async throws {
  let stops = try await GyeonggiBusStationAPIService.liveValue.searchStops(matching: "수원역")

  #expect(!stops.isEmpty)
  #expect(stops.contains { $0.name.contains("수원역") })
  #expect(stops.allSatisfy {
    if case .gyeonggi = $0.id { return true }
    return false
  })
}

@Test func searchSeoulBusStopsThroughAPI() async throws {
  let stops = try await SeoulBusStationAPIService.liveValue.searchStops(matching: "영등포역")

  #expect(!stops.isEmpty)
  #expect(stops.contains { $0.name.contains("영등포역") })
  #expect(stops.allSatisfy {
    if case .seoul = $0.id { return true }
    return false
  })
}

@Test func fetchNearbyGyeonggiBusStopsThroughAPI() async throws {
  let stops = try await GyeonggiBusStationAPIService.liveValue.fetchNearbyStops(
    latitude: BusStop.suwonStationExit7Outer.latitude,
    longitude: BusStop.suwonStationExit7Outer.longitude
  )

  #expect(!stops.isEmpty)
}

@Test func fetchNearbySeoulBusStopsThroughAPI() async throws {
  let stops = try await SeoulBusStationAPIService.liveValue.fetchNearbyStops(
    latitude: BusStop.theHyundaiSeoul.latitude,
    longitude: BusStop.theHyundaiSeoul.longitude
  )

  #expect(!stops.isEmpty)
  #expect(stops.allSatisfy {
    if case let .seoul(_, arsID) = $0.id { return !arsID.isEmpty }
    return false
  })
}

@Test func fetchNearbyStopsOutsideServiceAreasReturnsEmptyResult() async throws {
  let stops = try await LiveBusStopRepository.liveValue.fetchNearbyStops(
    latitude: 37.7749,
    longitude: -122.4194
  )

  #expect(stops.isEmpty)
}
