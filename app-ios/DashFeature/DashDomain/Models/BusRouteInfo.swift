public struct BusRouteInfo: Equatable, Hashable, Sendable {
  public let route: BusRoute
  public let routeTypeName: String
  public let regionName: String
  public let companyName: String
  public let startStopName: String
  public let endStopName: String

  public init(
    route: BusRoute,
    routeTypeName: String,
    regionName: String,
    companyName: String,
    startStopName: String,
    endStopName: String
  ) {
    self.route = route
    self.routeTypeName = routeTypeName
    self.regionName = regionName
    self.companyName = companyName
    self.startStopName = startStopName
    self.endStopName = endStopName
  }
}
