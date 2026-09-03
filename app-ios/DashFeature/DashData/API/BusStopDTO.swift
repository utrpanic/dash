import DashDomain

public struct GyeonggiBusStopListResponseDTO: Decodable, Equatable, Sendable {
  public let response: ResponseDTO

  func stops() -> [BusStop] {
    response.msgBody?.busStationList.values.compactMap { $0.toDomain() } ?? []
  }

  public struct ResponseDTO: Decodable, Equatable, Sendable {
    public let msgHeader: MessageHeaderDTO
    public let msgBody: MessageBodyDTO?
  }

  public struct MessageHeaderDTO: Decodable, Equatable, Sendable {
    public let resultCode: Int
    public let resultMessage: String
  }

  public struct MessageBodyDTO: Decodable, Equatable, Sendable {
    public let busStationList: FlexibleArrayDTO<GyeonggiBusStopDTO>
  }
}

extension GyeonggiBusStopListResponseDTO: BusStationAPIResponseDTO {
  var resultCode: Int { response.msgHeader.resultCode }
  var resultMessage: String { response.msgHeader.resultMessage }
}

public struct GyeonggiBusStopAroundListResponseDTO: Decodable, Equatable, Sendable {
  public let response: ResponseDTO

  func stops() -> [BusStop] {
    response.msgBody?.busStationAroundList.values.compactMap { $0.toDomain() } ?? []
  }

  public struct ResponseDTO: Decodable, Equatable, Sendable {
    public let msgHeader: GyeonggiBusStopListResponseDTO.MessageHeaderDTO
    public let msgBody: MessageBodyDTO?
  }

  public struct MessageBodyDTO: Decodable, Equatable, Sendable {
    public let busStationAroundList: FlexibleArrayDTO<GyeonggiBusStopDTO>
  }
}

extension GyeonggiBusStopAroundListResponseDTO: BusStationAPIResponseDTO {
  var resultCode: Int { response.msgHeader.resultCode }
  var resultMessage: String { response.msgHeader.resultMessage }
}

public struct GyeonggiBusStopDTO: Decodable, Equatable, Sendable {
  public let stationId: LossyIntDTO
  public let stationName: LossyStringDTO
  public let x: Double
  public let y: Double

  func toDomain() -> BusStop? {
    guard x != 0, y != 0 else { return nil }
    return BusStop(
      id: .gyeonggi(stopID: stationId.value),
      name: stationName.value,
      latitude: y,
      longitude: x
    )
  }
}

public struct SeoulBusStopDTO: Equatable, Sendable {
  let stopID: Int
  let name: String
  let arsID: String
  let longitude: Double
  let latitude: Double

  init(fields: [String: String]) throws {
    let fields = SeoulBusAPIFields(values: fields)
    guard let stopID = Int(fields.string("stId")) ?? Int(fields.string("stationId")) else {
      throw SeoulBusAPIError.invalidField("stId")
    }
    self.stopID = stopID
    name = Self.nonEmpty(fields.string("stNm"), fallback: fields.string("stationNm"))
    arsID = fields.string("arsId")
    guard let longitude = Double(fields.string("tmX")) ?? Double(fields.string("gpsX")),
          let latitude = Double(fields.string("tmY")) ?? Double(fields.string("gpsY"))
    else {
      throw SeoulBusAPIError.invalidField("tmX")
    }
    self.longitude = longitude
    self.latitude = latitude
  }

  func toDomain() -> BusStop {
    BusStop(
      id: .seoul(stopID: stopID, arsID: arsID),
      name: name,
      latitude: latitude,
      longitude: longitude
    )
  }

  private static func nonEmpty(_ value: String, fallback: String) -> String {
    value.isEmpty ? fallback : value
  }
}
