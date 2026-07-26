import Foundation

extension Array where Element == UpcomingBus {
  static var mock: [UpcomingBus] {
    return [
      UpcomingBus(
        boardingPoint: .suwonStation,
        busStop: .suwonStationExit7Outer,
        busRoute: .gyeonggi_13,
        timeIntervalUntilArrival: 2 * 60
      ),
      UpcomingBus(
        boardingPoint: .suwonStation,
        busStop: .suwonStationExit7Outer,
        busRoute: .gyeonggi_13_4,
        timeIntervalUntilArrival: 7 * 60
      ),
      UpcomingBus(
        boardingPoint: .suwonStation,
        busStop: .suwonStationExit7Inner,
        busRoute: .gyeonggi_13_1,
        timeIntervalUntilArrival: 12 * 60
      ),
      UpcomingBus(
        boardingPoint: .suwonStation,
        busStop: .suwonStationExit7Inner,
        busRoute: .gyeonggi_13_5,
        timeIntervalUntilArrival: 26 * 60
      ),
    ]
  }
}
