public struct BoardingPoint: Equatable, Hashable, Identifiable, Sendable {
  public let id: String
  public let name: String
  public let routes: [BusStop: Set<BusRoute>]

  public var centerLatitude: Double {
    routes.keys.map(\.latitude).reduce(0, +) / Double(routes.count)
  }

  public var centerLongitude: Double {
    routes.keys.map(\.longitude).reduce(0, +) / Double(routes.count)
  }

  public init(id: String, name: String, routes: [BusStop: Set<BusRoute>]) {
    precondition(!routes.isEmpty, "BoardingPoint requires at least one bus stop.")
    self.id = id
    self.name = name
    self.routes = routes
  }
}

public extension BoardingPoint {
  static let suwonStation = BoardingPoint(
    id: "suwon-station",
    name: "수원역",
    routes: [
      .suwonStationExit7Outer: [
        .gyeonggi_13,
        .gyeonggi_13_4,
        .gyeonggi_15_1,
      ],
      .suwonStationExit7Inner: [
        .gyeonggi_13_1,
        .gyeonggi_13_5,
      ],
    ]
  )
  static let homaesilSsangyongApartment = BoardingPoint(
    id: "homaesil-ssangyong-apartment",
    name: "쌍용아파트",
    routes: [
      .homaesilSsangyongApartment: [
        .gyeonggi_9,
        .gyeonggi_9_1,
        .gyeonggi_13,
      ],
    ]
  )
  static let yeongdeungpoStation = BoardingPoint(
    id: "yeongdeungpo-station",
    name: "영등포역",
    routes: [
      .yeongdeungpoStation: [
        .gyeonggi_88,
        .seoul_160,
        .seoul_600,
        .seoul_662,
        .seoul_8671,
      ],
    ]
  )
  static let theHyundaiSeoul = BoardingPoint(
    id: "the-hyundai-seoul",
    name: "더현대서울",
    routes: [
      .theHyundaiSeoul: [
        .gyeonggi_88,
        .seoul_662,
        .seoul_6628,
      ],
    ]
  )
}
