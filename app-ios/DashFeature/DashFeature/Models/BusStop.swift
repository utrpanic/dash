public struct BusStop: Equatable, Hashable, Identifiable, Sendable {
  public let id: Int
  public let name: String
  public let alias: String?
  public let latitude: Double
  public let longitude: Double

  public init(
    id: Int,
    name: String,
    alias: String? = nil,
    latitude: Double,
    longitude: Double
  ) {
    self.id = id
    self.name = name
    let alias = alias?.trimmingCharacters(in: .whitespacesAndNewlines)
    self.alias = alias?.isEmpty == false ? alias : nil
    self.latitude = latitude
    self.longitude = longitude
  }
}

public extension BusStop {
  static let suwonStationExit7Inner = BusStop(
    id: 202000106,
    name: "수원역7번출구.AK플라자",
    alias: "Inner Platform",
    latitude: 37.2674167,
    longitude: 127.0009
  )
  static let suwonStationExit7Outer = BusStop(
    id: 202000219,
    name: "수원역7번출구.AK플라자",
    alias: "Outer Platform",
    latitude: 37.2674667,
    longitude: 127.0009167
  )
  static let homaesilSsangyongApartment = BusStop(
    id: 201000096,
    name: "호매실쌍용아파트",
    alias: nil,
    latitude: 37.2678,
    longitude: 126.9513167
  )
  static let yeongdeungpoStation = BusStop(
    id: 118000005,
    name: "영등포역",
    alias: nil,
    latitude: 37.5158657465,
    longitude: 126.90509208
  )
  static let theHyundaiSeoul = BusStop(
    id: 118000197,
    name: "더현대서울",
    alias: nil,
    latitude: 37.5250045778,
    longitude: 126.9281836353
  )
}
