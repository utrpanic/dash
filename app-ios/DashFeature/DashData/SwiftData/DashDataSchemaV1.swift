import SwiftData

public enum DashDataSchemaV1: VersionedSchema {
  public static let versionIdentifier = Schema.Version(1, 0, 0)
  public static let models: [any PersistentModel.Type] = [
    BoardingPointConfigurationRecord.self,
    BoardingPointRecord.self,
    BoardingPointStopRecord.self,
    SelectedRouteRecord.self,
  ]

  @Model
  final class BoardingPointConfigurationRecord {
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
  final class BoardingPointRecord {
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
  final class BoardingPointStopRecord {
    @Attribute(.unique) var id: String
    var busStopID: Int
    var region: String
    var arsID: String?
    var name: String
    var alias: String?
    var latitude: Double
    var longitude: Double
    @Relationship(deleteRule: .cascade) var selectedRoutes: [SelectedRouteRecord]

    init(
      id: String,
      busStopID: Int,
      region: String,
      arsID: String?,
      name: String,
      alias: String?,
      latitude: Double,
      longitude: Double,
      selectedRoutes: [SelectedRouteRecord]
    ) {
      self.id = id
      self.busStopID = busStopID
      self.region = region
      self.arsID = arsID
      self.name = name
      self.alias = alias
      self.latitude = latitude
      self.longitude = longitude
      self.selectedRoutes = selectedRoutes
    }
  }

  @Model
  final class SelectedRouteRecord {
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
}
