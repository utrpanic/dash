public struct BusRouteListResponseDTO: Decodable, Equatable, Sendable {
  public let response: ResponseDTO

  func toDomain() -> [BusRoute] {
    response.msgBody.busRouteList.map { $0.toDomain() }
  }
}

extension BusRouteListResponseDTO: BusRouteAPIResponseDTO {
  var resultCode: Int { response.msgHeader.resultCode }
  var resultMessage: String { response.msgHeader.resultMessage }
}

public extension BusRouteListResponseDTO {
  struct ResponseDTO: Decodable, Equatable, Sendable {
    public let msgHeader: MessageHeaderDTO
    public let msgBody: MessageBodyDTO
  }

  struct MessageHeaderDTO: Decodable, Equatable, Sendable {
    public let resultCode: Int
    public let resultMessage: String
  }

  struct MessageBodyDTO: Decodable, Equatable, Sendable {
    public let busRouteList: [BusRouteDTO]
  }
}

public struct BusRouteDTO: Decodable, Equatable, Sendable {
  public let routeId: Int
  public let routeName: LossyStringDTO

  func toDomain() -> BusRoute {
    BusRoute(id: routeId, number: routeName.value, region: .gyeonggi)
  }
}

public struct BusRouteInfoResponseDTO: Decodable, Equatable, Sendable {
  public let response: ResponseDTO

  func toDomain() -> BusRouteInfo {
    response.msgBody.busRouteInfoItem.toDomain()
  }
}

extension BusRouteInfoResponseDTO: BusRouteAPIResponseDTO {
  var resultCode: Int { response.msgHeader.resultCode }
  var resultMessage: String { response.msgHeader.resultMessage }
}

public extension BusRouteInfoResponseDTO {
  struct ResponseDTO: Decodable, Equatable, Sendable {
    public let msgHeader: BusRouteListResponseDTO.MessageHeaderDTO
    public let msgBody: MessageBodyDTO
  }

  struct MessageBodyDTO: Decodable, Equatable, Sendable {
    public let busRouteInfoItem: BusRouteInfoDTO
  }
}

public struct BusRouteInfoDTO: Decodable, Equatable, Sendable {
  public let companyName: String?
  public let endStationName: String?
  public let regionName: String?
  public let routeId: Int
  public let routeName: LossyStringDTO
  public let routeTypeName: String?
  public let startStationName: String?

  func toDomain() -> BusRouteInfo {
    BusRouteInfo(
      route: BusRoute(id: routeId, number: routeName.value, region: .gyeonggi),
      routeTypeName: routeTypeName ?? "",
      regionName: regionName ?? "",
      companyName: companyName ?? "",
      startStationName: startStationName ?? "",
      endStationName: endStationName ?? ""
    )
  }
}

public struct BusRouteLineResponseDTO: Decodable, Equatable, Sendable {
  public let response: ResponseDTO

  func toDomain() -> [BusRouteLinePoint] {
    response.msgBody.busRouteLineList.map { $0.toDomain() }
  }
}

extension BusRouteLineResponseDTO: BusRouteAPIResponseDTO {
  var resultCode: Int { response.msgHeader.resultCode }
  var resultMessage: String { response.msgHeader.resultMessage }
}

public extension BusRouteLineResponseDTO {
  struct ResponseDTO: Decodable, Equatable, Sendable {
    public let msgHeader: BusRouteListResponseDTO.MessageHeaderDTO
    public let msgBody: MessageBodyDTO
  }

  struct MessageBodyDTO: Decodable, Equatable, Sendable {
    public let busRouteLineList: [BusRouteLineDTO]
  }
}

public struct BusRouteLineDTO: Decodable, Equatable, Sendable {
  public let lineSeq: Int
  public let x: Double
  public let y: Double

  func toDomain() -> BusRouteLinePoint {
    BusRouteLinePoint(sequence: lineSeq, x: x, y: y)
  }
}

public struct LossyStringDTO: Decodable, Equatable, Sendable {
  public let value: String

  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()

    if let string = try? container.decode(String.self) {
      value = string
    } else if let int = try? container.decode(Int.self) {
      value = String(int)
    } else {
      throw DecodingError.typeMismatch(
        String.self,
        DecodingError.Context(
          codingPath: decoder.codingPath,
          debugDescription: "Expected a string or integer value."
        )
      )
    }
  }
}

protocol BusRouteAPIResponseDTO {
  var resultCode: Int { get }
  var resultMessage: String { get }
}
