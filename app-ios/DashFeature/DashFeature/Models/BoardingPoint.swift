public struct BoardingPoint: Equatable, Hashable, Identifiable, Sendable {
  public let id: String
  public let name: String
  public let routes: [BusStop: Set<BusRoute>]
  public let busStopOrder: [BusStop.ID]

  public var centerLatitude: Double {
    routes.keys.map(\.latitude).reduce(0, +) / Double(routes.count)
  }

  public var centerLongitude: Double {
    routes.keys.map(\.longitude).reduce(0, +) / Double(routes.count)
  }

  public init(
    id: String,
    name: String,
    routes: [BusStop: Set<BusRoute>],
    busStopOrder: [BusStop.ID]? = nil
  ) {
    self.id = id
    self.name = name
    self.routes = routes

    let routeIDs = Set(routes.keys.map(\.id))
    var seen = Set<BusStop.ID>()
    let requestedOrder = busStopOrder ?? routes.keys.map(\.id)
    let normalizedOrder = requestedOrder.compactMap { id -> BusStop.ID? in
      guard routeIDs.contains(id), seen.insert(id).inserted else {
        return nil
      }
      return id
    }
    let remainingOrder = routes.keys
      .filter { !seen.contains($0.id) }
      .sorted {
        let comparison = $0.name.localizedStandardCompare($1.name)
        if comparison == .orderedSame {
          return $0.id < $1.id
        }
        return comparison == .orderedAscending
      }
      .map(\.id)
    self.busStopOrder = normalizedOrder + remainingOrder
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
    ],
    busStopOrder: [
      BusStop.suwonStationExit7Outer.id,
      BusStop.suwonStationExit7Inner.id,
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
