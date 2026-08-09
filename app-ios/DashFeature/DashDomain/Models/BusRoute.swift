public struct BusRoute: Equatable, Hashable, Identifiable, Sendable {
  public let id: Int
  public let number: String

  public init(id: Int, number: String) {
    self.id = id
    self.number = number
  }
}

public extension BusRoute {
  static let route9 = BusRoute(id: 200000103, number: "9")
  static let route9_1 = BusRoute(id: 200000186, number: "9-1")
  static let route13 = BusRoute(id: 200000037, number: "13")
  static let route13_1 = BusRoute(id: 200000069, number: "13-1")
  static let route13_4 = BusRoute(id: 200000185, number: "13-4")
  static let route13_5 = BusRoute(id: 200000090, number: "13-5")
  static let route15_1 = BusRoute(id: 200000152, number: "15-1")
  static let route88 = BusRoute(id: 212000001, number: "88")
  static let route160 = BusRoute(id: 100100033, number: "160")
  static let route600 = BusRoute(id: 100100085, number: "600")
  static let route662 = BusRoute(id: 100100550, number: "662")
  static let route6628 = BusRoute(id: 100100305, number: "6628")
  static let route8671 = BusRoute(id: 114000003, number: "8671")
}
