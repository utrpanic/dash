import Foundation
import Testing
@testable import DashData

@Test func gyeonggiArrivalListDecodesMissingBodyAsEmpty() throws {
  let data = Data(
    #"{"response":{"msgHeader":{"resultCode":0,"resultMessage":"정상적으로 처리되었습니다."}}}"#.utf8
  )

  let response = try JSONDecoder().decode(BusArrivalListResponseDTO.self, from: data)

  #expect(response.response.msgBody == nil)
}
