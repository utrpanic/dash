import DashDomain
import SwiftData

@ModelActor
public actor SwiftDataBoardingPointRepository: BoardingPointRepository {
  private static let configurationID = "boarding-point-configuration"

  public func loadConfiguration() throws -> BoardingPointConfiguration {
    let records = try modelContext.fetch(
      FetchDescriptor<BoardingPointConfigurationRecord>()
    )
    guard let record = records.first(where: { $0.id == Self.configurationID }) else {
      let configuration = initialConfiguration
      modelContext.insert(record(from: configuration))
      try modelContext.save()
      return configuration
    }
    return configuration(from: record)
  }

  public func saveConfiguration(_ configuration: BoardingPointConfiguration) throws {
    let existingRecords = try modelContext.fetch(
      FetchDescriptor<BoardingPointConfigurationRecord>()
    )
    for record in existingRecords where record.id == Self.configurationID {
      modelContext.delete(record)
    }

    modelContext.insert(record(from: configuration))
    try modelContext.save()
  }

  private func configuration(
    from record: BoardingPointConfigurationRecord
  ) -> BoardingPointConfiguration {
    BoardingPointConfiguration(
      boardingPoints: record.boardingPoints
        .sorted { $0.sortIndex < $1.sortIndex }
        .map(boardingPoint(from:)),
      currentBoardingPointID: record.currentBoardingPointID
    )
  }

  private func boardingPoint(from record: BoardingPointRecord) -> BoardingPoint {
    let routes = Dictionary(
      uniqueKeysWithValues: record.stops.map { stop in
        (
          BusStop(
            id: busStopID(from: stop),
            name: stop.name,
            alias: stop.alias,
            latitude: stop.latitude,
            longitude: stop.longitude
          ),
          Set(stop.selectedRoutes.map(busRoute(from:)))
        )
      }
    )
    return BoardingPoint(id: record.id, name: record.name, routes: routes)
  }

  private func busStopID(from record: BoardingPointStopRecord) -> BusStop.ID {
    BusStop.allKnown.first { $0.id.stationID == record.busStopID }?.id
      ?? .gyeonggi(stationID: record.busStopID)
  }

  private var initialConfiguration: BoardingPointConfiguration {
    BoardingPointConfiguration(
      boardingPoints: [
        .yeongdeungpoStation,
        .theHyundaiSeoul,
      ],
      currentBoardingPointID: BoardingPoint.yeongdeungpoStation.id
    )
  }

  private func busRoute(from record: SelectedRouteRecord) -> BusRoute {
    BusRoute(id: record.routeID, number: record.number)
  }

  private func record(
    from configuration: BoardingPointConfiguration
  ) -> BoardingPointConfigurationRecord {
    BoardingPointConfigurationRecord(
      id: Self.configurationID,
      currentBoardingPointID: configuration.currentBoardingPointID,
      boardingPoints: configuration.boardingPoints.enumerated().map {
        index,
        boardingPoint in
        record(from: boardingPoint, sortIndex: index)
      }
    )
  }

  private func record(
    from boardingPoint: BoardingPoint,
    sortIndex: Int
  ) -> BoardingPointRecord {
    let stops = boardingPoint.routes.keys
      .sorted { $0.id.stationID < $1.id.stationID }
      .map { stop in
        BoardingPointStopRecord(
          id: "\(boardingPoint.id)-\(stop.id.storageKey)",
          busStopID: stop.id.stationID,
          name: stop.name,
          alias: stop.alias,
          latitude: stop.latitude,
          longitude: stop.longitude,
          selectedRoutes: boardingPoint.routes[stop, default: []]
            .sorted { $0.id < $1.id }
            .map { route in
              SelectedRouteRecord(
                id: "\(boardingPoint.id)-\(stop.id.storageKey)-\(route.id)",
                routeID: route.id,
                number: route.number,
                region: {
                  switch stop.id {
                  case .gyeonggi:
                    "gyeonggi"
                  case .seoul:
                    "seoul"
                  }
                }()
              )
            }
        )
      }
    return BoardingPointRecord(
      id: boardingPoint.id,
      name: boardingPoint.name,
      sortIndex: sortIndex,
      stops: stops
    )
  }
}

@Model
private final class BoardingPointConfigurationRecord {
  @Attribute(.unique) var id: String
  var currentBoardingPointID: String?
  @Relationship(deleteRule: .cascade) var boardingPoints: [BoardingPointRecord]

  init(
    id: String,
    currentBoardingPointID: String?,
    boardingPoints: [BoardingPointRecord]
  ) {
    self.id = id
    self.currentBoardingPointID = currentBoardingPointID
    self.boardingPoints = boardingPoints
  }
}

@Model
private final class BoardingPointRecord {
  @Attribute(.unique) var id: String
  var name: String
  var sortIndex: Int
  @Relationship(deleteRule: .cascade) var stops: [BoardingPointStopRecord]

  init(
    id: String,
    name: String,
    sortIndex: Int,
    stops: [BoardingPointStopRecord]
  ) {
    self.id = id
    self.name = name
    self.sortIndex = sortIndex
    self.stops = stops
  }
}

@Model
private final class BoardingPointStopRecord {
  @Attribute(.unique) var id: String
  var busStopID: Int
  var name: String
  var alias: String?
  var latitude: Double
  var longitude: Double
  @Relationship(deleteRule: .cascade) var selectedRoutes: [SelectedRouteRecord]

  init(
    id: String,
    busStopID: Int,
    name: String,
    alias: String?,
    latitude: Double,
    longitude: Double,
    selectedRoutes: [SelectedRouteRecord]
  ) {
    self.id = id
    self.busStopID = busStopID
    self.name = name
    self.alias = alias
    self.latitude = latitude
    self.longitude = longitude
    self.selectedRoutes = selectedRoutes
  }
}

@Model
private final class SelectedRouteRecord {
  @Attribute(.unique) var id: String
  var routeID: Int
  var number: String
  var region: String

  init(id: String, routeID: Int, number: String, region: String) {
    self.id = id
    self.routeID = routeID
    self.number = number
    self.region = region
  }
}

public enum DashDataSchemaV1: VersionedSchema {
  public static let versionIdentifier = Schema.Version(1, 0, 0)
  public static let models: [any PersistentModel.Type] = [
    BoardingPointConfigurationRecord.self,
    BoardingPointRecord.self,
    BoardingPointStopRecord.self,
    SelectedRouteRecord.self,
  ]
}

public enum DashDataMigrationPlan: SchemaMigrationPlan {
  public static let schemas: [any VersionedSchema.Type] = [DashDataSchemaV1.self]
  public static let stages: [MigrationStage] = []
}
