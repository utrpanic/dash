import DashDomain

public struct BusStationViaRouteListResponseDTO: Decodable, Equatable, Sendable {
  public let response: ResponseDTO

  func toDomain() -> [BusRoute] {
    response.msgBody?.busRouteList.values.map { $0.toDomain() } ?? []
  }
}

extension BusStationViaRouteListResponseDTO: BusStationAPIResponseDTO {
  var resultCode: Int { response.msgHeader.resultCode }
  var resultMessage: String { response.msgHeader.resultMessage }
}

public extension BusStationViaRouteListResponseDTO {
  struct ResponseDTO: Decodable, Equatable, Sendable {
    public let msgHeader: MessageHeaderDTO
    public let msgBody: MessageBodyDTO?
  }

  struct MessageHeaderDTO: Decodable, Equatable, Sendable {
    public let resultCode: Int
    public let resultMessage: String
  }

  struct MessageBodyDTO: Decodable, Equatable, Sendable {
    public let busRouteList: FlexibleArrayDTO<BusStationViaRouteDTO>
  }
}

public struct BusStationViaRouteDTO: Decodable, Equatable, Sendable {
  public let routeId: LossyIntDTO
  public let routeName: LossyStringDTO

  func toDomain() -> BusRoute {
    BusRoute(id: routeId.value, number: routeName.value)
  }
}

protocol BusStationAPIResponseDTO {
  var resultCode: Int { get }
  var resultMessage: String { get }
}
