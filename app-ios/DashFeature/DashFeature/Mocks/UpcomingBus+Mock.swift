import DashDomain
import Foundation

extension Array where Element == UpcomingBus {
  static var mock: [UpcomingBus] {
    return [
      UpcomingBus(
        boardingPoint: .suwonStation,
        busStop: .suwonStationExit7Outer,
        busRoute: .route13,
        timeIntervalUntilArrival: 2 * 60
      ),
      UpcomingBus(
        boardingPoint: .suwonStation,
        busStop: .suwonStationExit7Outer,
        busRoute: .route13_4,
        timeIntervalUntilArrival: 7 * 60
      ),
      UpcomingBus(
        boardingPoint: .suwonStation,
        busStop: .suwonStationExit7Inner,
        busRoute: .route13_1,
        timeIntervalUntilArrival: 12 * 60
      ),
      UpcomingBus(
        boardingPoint: .suwonStation,
        busStop: .suwonStationExit7Inner,
        busRoute: .route13_5,
        timeIntervalUntilArrival: 26 * 60
      ),
    ]
  }
}
