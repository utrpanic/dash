import DashDomain
import SwiftData

@ModelActor
public actor SwiftDataBoardingPointRepository: BoardingPointRepository {
  private typealias BoardingPointConfigurationRecord = DashDataSchemaV2.BoardingPointConfigurationRecord
  private typealias BoardingPointRecord = DashDataSchemaV2.BoardingPointRecord
  private typealias BoardingPointStopRecord = DashDataSchemaV2.BoardingPointStopRecord
  private typealias SelectedRouteRecord = DashDataSchemaV2.SelectedRouteRecord

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
    return try configuration(from: record)
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
  ) throws -> BoardingPointConfiguration {
    try BoardingPointConfiguration(
      boardingPoints: record.boardingPoints
        .sorted { $0.sortIndex < $1.sortIndex }
        .map(boardingPoint(from:)),
      currentBoardingPointID: record.currentBoardingPointID
    )
  }

  private func boardingPoint(from record: BoardingPointRecord) throws -> BoardingPoint {
    let routes = Dictionary(
      uniqueKeysWithValues: try record.stops.map { stop in
        (
          BusStop(
            id: try busStopID(from: stop),
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

  private func busStopID(from record: BoardingPointStopRecord) throws -> BusStop.ID {
    switch record.region {
    case "gyeonggi":
      return .gyeonggi(stopID: record.busStopID)
    case "seoul":
      guard let arsID = record.arsID else {
        throw BusStopPersistenceError.invalidIdentity(record.id)
      }
      return .seoul(stopID: record.busStopID, arsID: arsID)
    default:
      throw BusStopPersistenceError.invalidIdentity(record.id)
    }
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
      .sorted { $0.id.stopID < $1.id.stopID }
      .map { stop in
        BoardingPointStopRecord(
          id: "\(boardingPoint.id)-\(stop.id.storageKey)",
          busStopID: stop.id.stopID,
          region: {
            switch stop.id {
            case .gyeonggi: "gyeonggi"
            case .seoul: "seoul"
            }
          }(),
          arsID: {
            switch stop.id {
            case .gyeonggi: nil
            case let .seoul(_, arsID): arsID
            }
          }(),
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
