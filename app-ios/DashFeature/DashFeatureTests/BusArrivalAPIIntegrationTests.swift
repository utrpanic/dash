import Testing
import DashData
@testable import DashFeature

@Test func fetchBusArrivalsThroughFeature() async throws {
  let api = GyeonggiBusArrivalAPIService.liveValue
  let arrivals = try await api.fetchArrivals(200000275)
  let firstArrival = try #require(arrivals.first)

  #expect(!arrivals.isEmpty)
  #expect(firstArrival.stationId == 200000275)
  #expect(firstArrival.route.id > 0)
  #expect(!firstArrival.route.number.isEmpty)
}

@Test func fetchBusArrivalThroughFeature() async throws {
  let api = GyeonggiBusArrivalAPIService.liveValue
  let arrivals = try await api.fetchArrivals(200000275)
  let firstArrival = try #require(arrivals.first)

  let arrival = try await api.fetchArrival(
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
  let api = GyeonggiBusArrivalAPIService.liveValue
  let stationIds = [
    BusStop.suwonStationExit7Outer.id.stationID,
    BusStop.suwonStationExit7Inner.id.stationID,
    BusStop.homaesilSsangyongApartment.id.stationID,
  ]

  for stationId in stationIds {
    _ = try await api.fetchArrivals(stationId)
  }
}
