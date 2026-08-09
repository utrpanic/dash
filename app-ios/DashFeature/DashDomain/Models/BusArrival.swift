import Foundation

public struct BusArrival: Equatable, Hashable, Identifiable, Sendable {
  public var id: String {
    "\(stopID)-\(route.id)-\(stopOrder)"
  }

  public let stopID: Int
  public let route: BusRoute
  public let stopOrder: Int
  public let operationState: String
  public let firstPrediction: BusArrivalPrediction?
  public let secondPrediction: BusArrivalPrediction?

  public init(
    stopID: Int,
    route: BusRoute,
    stopOrder: Int,
    operationState: String,
    firstPrediction: BusArrivalPrediction?,
    secondPrediction: BusArrivalPrediction?
  ) {
    self.stopID = stopID
    self.route = route
    self.stopOrder = stopOrder
    self.operationState = operationState
    self.firstPrediction = firstPrediction
    self.secondPrediction = secondPrediction
  }

  public func upcomingBuses(boardingPoint: BoardingPoint, busStop: BusStop) -> [UpcomingBus] {
    [firstPrediction, secondPrediction]
      .compactMap { prediction in
        guard let timeInterval = prediction?.timeIntervalUntilArrival else {
          return nil
        }

        return UpcomingBus(
          boardingPoint: boardingPoint,
          busStop: busStop,
          busRoute: route,
          timeIntervalUntilArrival: timeInterval
        )
      }
  }
}

public struct BusArrivalPrediction: Equatable, Hashable, Sendable {
  public let minutes: Int?
  public let seconds: Int?
  public let locationNumber: Int?
  public let plateNumber: String
  public let remainingSeatCount: Int?
  public let stateCode: Int?
  public let stopName: String
  public let vehicleId: Int?

  public var timeIntervalUntilArrival: TimeInterval? {
    if let seconds {
      return TimeInterval(seconds)
    }

    if let minutes {
      return TimeInterval(minutes * 60)
    }

    return nil
  }

  public init(
    minutes: Int?,
    seconds: Int?,
    locationNumber: Int?,
    plateNumber: String,
    remainingSeatCount: Int?,
    stateCode: Int?,
    stopName: String,
    vehicleId: Int?
  ) {
    self.minutes = minutes
    self.seconds = seconds
    self.locationNumber = locationNumber
    self.plateNumber = plateNumber
    self.remainingSeatCount = remainingSeatCount
    self.stateCode = stateCode
    self.stopName = stopName
    self.vehicleId = vehicleId
  }
}
