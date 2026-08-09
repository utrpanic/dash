import Testing
import DashData
@testable import DashFeature

@Test func fetchBusArrivalsThroughFeature() async throws {
  let api = GyeonggiBusArrivalAPIService.liveValue
  let arrivals = try await api.fetchArrivals(200000275)
  let firstArrival = try #require(arrivals.first)

  #expect(!arrivals.isEmpty)
  #expect(firstArrival.stationId.value == 200000275)
  #expect(firstArrival.routeId.value > 0)
  #expect(!firstArrival.routeName.value.isEmpty)
}

@Test func fetchBusArrivalThroughFeature() async throws {
  let api = GyeonggiBusArrivalAPIService.liveValue
  let arrivals = try await api.fetchArrivals(200000275)
  let firstArrival = try #require(arrivals.first)

  let arrival = try await api.fetchArrival(
    firstArrival.stationId.value,
    firstArrival.routeId.value,
    firstArrival.staOrder.value
  )

  #expect(arrival.stationId.value == firstArrival.stationId.value)
  #expect(arrival.routeId.value == firstArrival.routeId.value)
  #expect(!arrival.routeName.value.isEmpty)
  #expect(arrival.staOrder.value == firstArrival.staOrder.value)
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
