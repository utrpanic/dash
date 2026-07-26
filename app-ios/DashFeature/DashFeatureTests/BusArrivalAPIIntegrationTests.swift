import Testing
@testable import DashFeature

@Test func fetchBusArrivalsThroughFeature() async throws {
  let arrivals = try await BusArrivalAPIClient.liveValue.fetchArrivals(200000275)
  let firstArrival = try #require(arrivals.first)

  #expect(!arrivals.isEmpty)
  #expect(firstArrival.stationId == 200000275)
  #expect(firstArrival.route.id > 0)
  #expect(!firstArrival.route.number.isEmpty)
}

@Test func fetchBusArrivalThroughFeature() async throws {
  let arrivals = try await BusArrivalAPIClient.liveValue.fetchArrivals(200000275)
  let firstArrival = try #require(arrivals.first)

  let arrival = try await BusArrivalAPIClient.liveValue.fetchArrival(
    firstArrival.stationId,
    firstArrival.route.id,
    firstArrival.stationOrder
  )

  #expect(arrival.stationId == firstArrival.stationId)
  #expect(arrival.route.id == firstArrival.route.id)
  #expect(!arrival.route.number.isEmpty)
  #expect(arrival.stationOrder == firstArrival.stationOrder)
}

@Test func fetchBoardingPointBusArrivalsThroughFeature() async throws {
  let stationIds = [
    BusStop.suwonStationExit7Outer.id,
    BusStop.suwonStationExit7Inner.id,
    BusStop.homaesilSsangyongApartment.id,
  ]

  for stationId in stationIds {
    _ = try await BusArrivalAPIClient.liveValue.fetchArrivals(stationId)
  }
}
