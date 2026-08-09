import Foundation
import Testing
@testable import DashFeature

@Test func busStationViaRouteResponseDecodesSingleRoute() throws {
  let data = Data(
    """
    {
      "response": {
        "msgHeader": {
          "resultCode": 0,
          "resultMessage": "정상적으로 처리되었습니다."
        },
        "msgBody": {
          "busRouteList": {
            "routeId": "200000037",
            "routeName": 13,
            "staOrder": "42"
          }
        }
      }
    }
    """.utf8
  )

  let response = try JSONDecoder().decode(BusStationViaRouteListResponseDTO.self, from: data)

  #expect(
    response.toDomain() == [.route13]
  )
}
