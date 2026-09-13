import Testing
import DashData
@testable import DashFeature

@Suite(.serialized)
struct BusArrivalAPIIntegrationTests {
  @Test func fetchBusArrivalsThroughFeature() async throws {
    let api = GyeonggiBusArrivalAPIService.liveValue
    let arrivals = try await api.fetchArrivals(200000275)

    for arrival in arrivals {
      #expect(arrival.stationId.value == 200000275)
      #expect(arrival.routeId.value > 0)
      #expect(!arrival.routeName.value.isEmpty)
    }
  }

  @Test func fetchBusArrivalThroughFeature() async throws {
    let api = GyeonggiBusArrivalAPIService.liveValue
    let arrivals = try await api.fetchArrivals(200000275)
    guard let firstArrival = arrivals.first else { return }

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
    let stopIDs = [
      BusStop.suwonStationExit7Outer.id.stopID,
      BusStop.suwonStationExit7Inner.id.stopID,
      BusStop.homaesilSsangyongApartment.id.stopID,
    ]

    for stopID in stopIDs {
      _ = try await api.fetchArrivals(stopID)
    }
  }
}
