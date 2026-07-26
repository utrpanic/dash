import Foundation

public struct BusArrival: Equatable, Hashable, Identifiable, Sendable {
  public var id: String {
    "\(stationId)-\(route.id)-\(stationOrder)"
  }

  public let stationId: Int
  public let route: BusRoute
  public let stationOrder: Int
  public let destinationName: String
  public let operationState: String
  public let firstPrediction: BusArrivalPrediction?
  public let secondPrediction: BusArrivalPrediction?

  public init(
    stationId: Int,
    route: BusRoute,
    stationOrder: Int,
    destinationName: String,
    operationState: String,
    firstPrediction: BusArrivalPrediction?,
    secondPrediction: BusArrivalPrediction?
  ) {
    self.stationId = stationId
    self.route = route
    self.stationOrder = stationOrder
    self.destinationName = destinationName
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
  public let stationName: String
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
    stationName: String,
    vehicleId: Int?
  ) {
    self.minutes = minutes
    self.seconds = seconds
    self.locationNumber = locationNumber
    self.plateNumber = plateNumber
    self.remainingSeatCount = remainingSeatCount
    self.stateCode = stateCode
    self.stationName = stationName
    self.vehicleId = vehicleId
  }
}
