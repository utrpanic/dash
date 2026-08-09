import Testing
@testable import DashFeature

@Test func seoulBusRouteAtStationMapsRoute() throws {
  let route = try SeoulBusRouteAtStationDTO(
    fields: [
      "busRouteId": "100100550",
      "busRouteNm": "662",
      "stEnd": "여의나루역",
    ]
  ).toDomain()

  #expect(route == .route662)
}
