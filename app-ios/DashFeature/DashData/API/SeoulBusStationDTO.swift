import DashDomain

struct SeoulBusRouteAtStationDTO: Equatable, Sendable {
  let routeID: Int
  let routeNumber: String

  init(fields: [String: String]) throws {
    let fields = SeoulBusAPIFields(values: fields)
    routeID = try fields.requiredInt("busRouteId")
    routeNumber = fields.string("busRouteNm")
  }

  func toDomain() -> BusRoute {
    BusRoute(id: routeID, number: routeNumber)
  }
}
