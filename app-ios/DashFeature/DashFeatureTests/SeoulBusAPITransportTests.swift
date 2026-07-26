import Foundation
import Testing
@testable import DashFeature

@Test func seoulBusAPIJSONParserParsesItemList() throws {
  let data = Data(
    #"""
    {
      "msgHeader": {
        "headerCd": "0",
        "headerMsg": "OK",
        "itemCount": 2
      },
      "msgBody": {
        "itemList": [
          {
            "busRouteId": "100100550",
            "staOrd": 29,
            "lastBus": false
          },
          {
            "busRouteId": 100100305,
            "staOrd": "31"
          }
        ]
      }
    }
    """#.utf8
  )

  let response = try SeoulBusAPIJSONParser.parse(data)

  #expect(response.header["headerCd"] == "0")
  #expect(response.header["itemCount"] == "2")
  #expect(response.items.count == 2)
  #expect(response.items[0]["staOrd"] == "29")
  #expect(response.items[0]["lastBus"] == "false")
  #expect(response.items[1]["busRouteId"] == "100100305")
}

@Test func seoulBusAPIJSONParserParsesSingleItem() throws {
  let data = Data(
    #"""
    {
      "msgHeader": {
        "headerCd": "0"
      },
      "msgBody": {
        "itemList": {
          "busRouteId": "100100550"
        }
      }
    }
    """#.utf8
  )

  let response = try SeoulBusAPIJSONParser.parse(data)

  #expect(response.items == [["busRouteId": "100100550"]])
}
