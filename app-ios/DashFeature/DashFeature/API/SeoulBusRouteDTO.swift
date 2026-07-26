struct SeoulBusRouteDTO: Equatable, Sendable {
  let id: Int
  let number: String

  init(fields: [String: String]) throws {
    let fields = SeoulBusAPIFields(values: fields)
    id = try fields.requiredInt("busRouteId")
    number = fields.string("busRouteNm")
  }

  func toDomain() -> BusRoute {
    BusRoute(id: id, number: number, region: .seoul)
  }
}

struct SeoulBusRouteInfoDTO: Equatable, Sendable {
  let id: Int
  let number: String
  let routeType: Int?
  let companyName: String
  let startStationName: String
  let endStationName: String

  init(fields: [String: String]) throws {
    let fields = SeoulBusAPIFields(values: fields)
    id = try fields.requiredInt("busRouteId")
    number = fields.string("busRouteNm")
    routeType = fields.optionalInt("routeType")
    companyName = fields.string("corpNm")
    startStationName = fields.string("stStationNm")
    endStationName = fields.string("edStationNm")
  }

  func toDomain() -> BusRouteInfo {
    BusRouteInfo(
      route: BusRoute(id: id, number: number, region: .seoul),
      routeTypeName: routeType.map(Self.routeTypeName) ?? "",
      regionName: "서울",
      companyName: companyName,
      startStationName: startStationName,
      endStationName: endStationName
    )
  }

  private static func routeTypeName(_ routeType: Int) -> String {
    switch routeType {
    case 0: "공용"
    case 1: "공항"
    case 2: "마을"
    case 3: "간선"
    case 4: "지선"
    case 5: "순환"
    case 6: "광역"
    case 7: "인천"
    case 8: "경기"
    case 9: "폐지"
    case 10: "관광"
    case 13: "동행"
    case 14: "한강"
    case 15: "심야"
    default: ""
    }
  }
}

struct SeoulBusRouteLineDTO: Equatable, Sendable {
  let sequence: Int
  let x: Double
  let y: Double

  init(fields: [String: String]) throws {
    let fields = SeoulBusAPIFields(values: fields)
    sequence = try fields.requiredInt("no")
    x = try fields.requiredDouble("gpsX")
    y = try fields.requiredDouble("gpsY")
  }

  func toDomain() -> BusRouteLinePoint {
    BusRouteLinePoint(sequence: sequence, x: x, y: y)
  }
}
