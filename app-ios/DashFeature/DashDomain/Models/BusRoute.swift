public struct BusRoute: Equatable, Hashable, Identifiable, Sendable {
  public enum Region: Equatable, Hashable, Sendable {
    case gyeonggi
    case seoul
  }

  public let id: Int
  public let number: String
  public let region: Region

  public init(id: Int, number: String, region: Region) {
    self.id = id
    self.number = number
    self.region = region
  }
}

public extension BusRoute {
  static let gyeonggi_9 = BusRoute(id: 200000103, number: "9", region: .gyeonggi)
  static let gyeonggi_9_1 = BusRoute(id: 200000186, number: "9-1", region: .gyeonggi)
  static let gyeonggi_13 = BusRoute(id: 200000037, number: "13", region: .gyeonggi)
  static let gyeonggi_13_1 = BusRoute(id: 200000069, number: "13-1", region: .gyeonggi)
  static let gyeonggi_13_4 = BusRoute(id: 200000185, number: "13-4", region: .gyeonggi)
  static let gyeonggi_13_5 = BusRoute(id: 200000090, number: "13-5", region: .gyeonggi)
  static let gyeonggi_15_1 = BusRoute(id: 200000152, number: "15-1", region: .gyeonggi)
  static let gyeonggi_88 = BusRoute(id: 212000001, number: "88", region: .gyeonggi)
  static let seoul_160 = BusRoute(id: 100100033, number: "160", region: .seoul)
  static let seoul_600 = BusRoute(id: 100100085, number: "600", region: .seoul)
  static let seoul_662 = BusRoute(id: 100100550, number: "662", region: .seoul)
  static let seoul_6628 = BusRoute(id: 100100305, number: "6628", region: .seoul)
  static let seoul_8671 = BusRoute(id: 114000003, number: "8671", region: .seoul)
}
