public struct BoardingPoint: Equatable, Hashable, Identifiable, Sendable {
  public let id: String
  public let name: String
  public let routes: [BusStop: Set<BusRoute>]

  public var hasSelectedRoutes: Bool {
    routes.values.contains { !$0.isEmpty }
  }

  public var centerLatitude: Double? {
    guard !routes.isEmpty else { return nil }
    return routes.keys.map(\.latitude).reduce(0, +) / Double(routes.count)
  }

  public var centerLongitude: Double? {
    guard !routes.isEmpty else { return nil }
    return routes.keys.map(\.longitude).reduce(0, +) / Double(routes.count)
  }

  public init(
    id: String,
    name: String,
    routes: [BusStop: Set<BusRoute>]
  ) {
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
        .route13,
        .route13_4,
        .route15_1,
      ],
      .suwonStationExit7Inner: [
        .route13_1,
        .route13_5,
      ],
    ]
  )
  static let homaesilSsangyongApartment = BoardingPoint(
    id: "homaesil-ssangyong-apartment",
    name: "쌍용아파트",
    routes: [
      .homaesilSsangyongApartment: [
        .route9,
        .route9_1,
        .route13,
      ],
    ]
  )
  static let yeongdeungpoStation = BoardingPoint(
    id: "yeongdeungpo-station",
    name: "영등포역",
    routes: [
      .yeongdeungpoStation: [
        .route88,
        .route160,
        .route600,
        .route662,
        .route8671,
      ],
    ]
  )
  static let theHyundaiSeoul = BoardingPoint(
    id: "the-hyundai-seoul",
    name: "더현대서울",
    routes: [
      .theHyundaiSeoul: [
        .route88,
        .route662,
        .route6628,
      ],
    ]
  )
}
