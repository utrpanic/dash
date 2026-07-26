import ComposableArchitecture
import Testing
@testable import DashFeature

private let seoulArrivalSampleRouteID = BusRoute.seoul_662.id

@Test func fetchSeoulBusArrivalsByRouteThroughFeature() async throws {
  let arrivals = try await SeoulBusArrivalAPIClient.liveValue.fetchArrivalsByRoute(
    seoulArrivalSampleRouteID
  )
  let firstArrival = try #require(arrivals.first)

  #expect(firstArrival.route.id == seoulArrivalSampleRouteID)
  #expect(!firstArrival.route.number.isEmpty)
  #expect(firstArrival.stationId > 0)
  #expect(firstArrival.stationOrder > 0)
}

@Test func fetchSeoulBusArrivalThroughFeature() async throws {
  let arrivals = try await SeoulBusArrivalAPIClient.liveValue.fetchArrivalsByRoute(
    seoulArrivalSampleRouteID
  )
  let expectedArrival = try #require(arrivals.first)

  let arrival = try await SeoulBusArrivalAPIClient.liveValue.fetchArrival(
    expectedArrival.stationId,
    expectedArrival.route.id,
    expectedArrival.stationOrder
  )

  #expect(arrival.stationId == expectedArrival.stationId)
  #expect(arrival.route.id == expectedArrival.route.id)
  #expect(arrival.stationOrder == expectedArrival.stationOrder)
}

@Test func fetchSeoulLowFloorBusArrivalsThroughFeature() async throws {
  let arrivals = try await SeoulBusArrivalAPIClient.liveValue.fetchArrivalsByRoute(
    seoulArrivalSampleRouteID
  )
  let stationId = try #require(arrivals.first?.stationId)

  _ = try await SeoulBusArrivalAPIClient.liveValue.fetchLowFloorArrivals(stationId)
}

@Test func fetchSeoulLowFloorBusArrivalThroughFeature() async throws {
  let arrivals = try await SeoulBusArrivalAPIClient.liveValue.fetchArrivalsByRoute(
    seoulArrivalSampleRouteID
  )
  let expectedArrival = try #require(arrivals.first)

  let arrival = try await SeoulBusArrivalAPIClient.liveValue.fetchLowFloorArrival(
    expectedArrival.stationId,
    expectedArrival.route.id,
    expectedArrival.stationOrder
  )

  #expect(arrival.stationId == expectedArrival.stationId)
  #expect(arrival.route.id == expectedArrival.route.id)
  #expect(arrival.stationOrder == expectedArrival.stationOrder)
}
