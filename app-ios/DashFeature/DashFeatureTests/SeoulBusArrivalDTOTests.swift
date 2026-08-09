import Testing
@testable import DashFeature

@Test func seoulBusArrivalUsesRouteAbbreviationForDisplay() throws {
  let arrival = try SeoulBusArrivalDTO(
    fields: [
      "stId": "118000005",
      "busRouteId": "212000001",
      "rtNm": "88부천",
      "busRouteAbrv": "88",
      "staOrd": "12",
    ]
  ).toDomain()

  #expect(arrival.route.number == "88")
}
