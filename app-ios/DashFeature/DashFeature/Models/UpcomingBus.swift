import Foundation

public struct UpcomingBus: Equatable, Hashable, Identifiable, Sendable {
  public var id: String {
    "\(boardingPoint.id)-\(busStop.id)-\(busRoute.id)-\(timeIntervalUntilArrival)"
  }

  public let boardingPoint: BoardingPoint
  public let busStop: BusStop
  public let busRoute: BusRoute
  public let timeIntervalUntilArrival: TimeInterval

  public init(
    boardingPoint: BoardingPoint,
    busStop: BusStop,
    busRoute: BusRoute,
    timeIntervalUntilArrival: TimeInterval
  ) {
    self.boardingPoint = boardingPoint
    self.busStop = busStop
    self.busRoute = busRoute
    self.timeIntervalUntilArrival = timeIntervalUntilArrival
  }
}

extension Array where Element == UpcomingBus {
  var sortedByArrival: [UpcomingBus] {
    sorted { $0.timeIntervalUntilArrival < $1.timeIntervalUntilArrival }
  }
}
