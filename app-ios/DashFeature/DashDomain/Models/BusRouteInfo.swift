public struct BusRouteInfo: Equatable, Hashable, Sendable {
  public let route: BusRoute
  public let routeTypeName: String
  public let regionName: String
  public let companyName: String
  public let startStationName: String
  public let endStationName: String

  public init(
    route: BusRoute,
    routeTypeName: String,
    regionName: String,
    companyName: String,
    startStationName: String,
    endStationName: String
  ) {
    self.route = route
    self.routeTypeName = routeTypeName
    self.regionName = regionName
    self.companyName = companyName
    self.startStationName = startStationName
    self.endStationName = endStationName
  }
}
