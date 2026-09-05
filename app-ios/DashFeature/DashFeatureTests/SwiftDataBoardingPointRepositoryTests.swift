import DashDomain
import Foundation
import SwiftData
import Testing
@testable import DashData

@Suite @MainActor
struct SwiftDataBoardingPointRepositoryTests {
  @Test func preservesFullIdentityAfterReopeningStore() async throws {
    let directory = try makeDirectory()
    defer { try? FileManager.default.removeItem(at: directory) }
    let url = directory.appending(path: "configuration.store")
    let expected = configuration(stops: [
      stop(.seoul(stopID: 999000001, arsID: "00123")),
      stop(.gyeonggi(stopID: 999000001)),
      stop(.seoul(stopID: 999000002, arsID: "")),
    ])

    try await save(expected, to: url)
    #expect(try await load(from: url) == expected)
    // Saving a second configuration also exercises replacement of existing data.
    let updated = configuration(stops: [stop(.seoul(stopID: 999000003, arsID: "00456"))])
    try await save(updated, to: url)
    #expect(try await load(from: url) == updated)
  }

  @Test func migratesV1StorageKeysIncludingStopsWithoutRoutes() async throws {
    let directory = try makeDirectory()
    defer { try? FileManager.default.removeItem(at: directory) }
    let url = directory.appending(path: "configuration.store")
    let expected = configuration(stops: [
      stop(.seoul(stopID: 999000001, arsID: "00123")),
      stop(.gyeonggi(stopID: 999000001)),
      stop(.seoul(stopID: 999000002, arsID: "")),
      // Persisted identity must take precedence over the known-stop table.
      stop(.seoul(stopID: BusStop.yeongdeungpoStation.id.stopID, arsID: "00199")),
    ])
    try seedV1(expected, at: url, usesStorageKey: true)

    #expect(try await load(from: url) == expected)
    // Reopening V2 must not depend on rerunning migration.
    #expect(try await load(from: url) == expected)
  }

  @Test func migratesOriginalV1NumericKeys() async throws {
    let directory = try makeDirectory()
    defer { try? FileManager.default.removeItem(at: directory) }
    let url = directory.appending(path: "configuration.store")
    let expected = BoardingPointConfiguration(
      boardingPoints: [.theHyundaiSeoul, .suwonStation, .yeongdeungpoStation],
      currentBoardingPointID: BoardingPoint.suwonStation.id
    )
    try seedV1(expected, at: url, usesStorageKey: false)

    #expect(try await load(from: url) == expected)
  }

  @Test func migratesUnknownNumericKeysUsingSavedRouteRegion() async throws {
    let directory = try makeDirectory()
    defer { try? FileManager.default.removeItem(at: directory) }
    let url = directory.appending(path: "configuration.store")
    let expected = configuration(stops: [
      stop(.seoul(stopID: 999000001, arsID: "")),
      stop(.gyeonggi(stopID: 999000002)),
    ], includesRoutesForEveryStop: true)
    try seedV1(expected, at: url, usesStorageKey: false)

    #expect(try await load(from: url) == expected)
  }

  @Test func rejectsAmbiguousLegacyIdentityWithoutReplacingStore() throws {
    let directory = try makeDirectory()
    defer { try? FileManager.default.removeItem(at: directory) }
    let url = directory.appending(path: "configuration.store")
    let expected = configuration(stops: [stop(.gyeonggi(stopID: 999000001))])
    try seedV1(expected, at: url, usesStorageKey: false)

    #expect(throws: (any Error).self) {
      _ = try container(at: url, version: DashDataSchemaV2.self)
    }
    // A failed migration must leave the original V1 data available.
    let original = try container(at: url, version: DashDataSchemaV1.self)
    let context = ModelContext(original)
    let records = try context.fetch(FetchDescriptor<BoardingPointStopRecord>())
    #expect(records.count == 1)
    #expect(records.first?.busStopID == 999000001)
  }

  @Test func initializesFreshV2Store() async throws {
    let directory = try makeDirectory()
    defer { try? FileManager.default.removeItem(at: directory) }
    let url = directory.appending(path: "configuration.store")
    let expected = BoardingPointConfiguration(
      boardingPoints: [.yeongdeungpoStation, .theHyundaiSeoul],
      currentBoardingPointID: BoardingPoint.yeongdeungpoStation.id
    )
    #expect(try await load(from: url) == expected)
    #expect(try await load(from: url) == expected)
  }

  private func makeDirectory() throws -> URL {
    let url = FileManager.default.temporaryDirectory
      .appending(path: "DashPersistenceTests-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
  }

  private func container(
    at url: URL,
    version: any VersionedSchema.Type = DashDataSchemaV2.self
  ) throws -> ModelContainer {
    let schema = Schema(versionedSchema: version)
    return try ModelContainer(
      for: schema,
      migrationPlan: version.versionIdentifier == DashDataSchemaV1.versionIdentifier
        ? nil : DashDataMigrationPlan.self,
      configurations: ModelConfiguration(schema: schema, url: url)
    )
  }

  private func save(_ configuration: BoardingPointConfiguration, to url: URL) async throws {
    let repository = SwiftDataBoardingPointRepository(modelContainer: try container(at: url))
    try await repository.saveConfiguration(configuration)
  }

  private func load(from url: URL) async throws -> BoardingPointConfiguration {
    let repository = SwiftDataBoardingPointRepository(modelContainer: try container(at: url))
    return try await repository.loadConfiguration()
  }

  private func stop(_ id: BusStop.ID) -> BusStop {
    BusStop(id: id, name: "검색한 정류장", alias: "출근", latitude: 37.5, longitude: 127.0)
  }

  private func configuration(
    stops: [BusStop],
    includesRoutesForEveryStop: Bool = false
  ) -> BoardingPointConfiguration {
    let point = BoardingPoint(
      id: "commute-point-with-hyphens",
      name: "출근",
      routes: Dictionary(uniqueKeysWithValues: stops.enumerated().map { index, stop in
        (stop, includesRoutesForEveryStop || index == 1 ? Set([BusRoute.route13]) : Set())
      })
    )
    return BoardingPointConfiguration(boardingPoints: [point], currentBoardingPointID: point.id)
  }

  // Build an on-disk V1 database with the actual frozen models, not V2 fixtures.
  private func seedV1(
    _ configuration: BoardingPointConfiguration,
    at url: URL,
    usesStorageKey: Bool
  ) throws {
    try autoreleasepool {
      let container = try container(at: url, version: DashDataSchemaV1.self)
      let context = ModelContext(container)
      let points = configuration.boardingPoints.enumerated().map { index, point in
        let stops = point.routes.map { stop, routes in
          let key = "\(point.id)-\(usesStorageKey ? stop.id.storageKey : String(stop.id.stopID))"
          let region: String = switch stop.id {
          case .gyeonggi: "gyeonggi"
          case .seoul: "seoul"
          }
          return BoardingPointStopRecord(
            id: key,
            busStopID: stop.id.stopID,
            name: stop.name,
            alias: stop.alias,
            latitude: stop.latitude,
            longitude: stop.longitude,
            selectedRoutes: routes.map {
              SelectedRouteRecord(
                id: "\(key)-\($0.id)", routeID: $0.id, number: $0.number, region: region
              )
            }
          )
        }
        return BoardingPointRecord(id: point.id, name: point.name, sortIndex: index, stops: stops)
      }
      context.insert(BoardingPointConfigurationRecord(
        id: "boarding-point-configuration",
        currentBoardingPointID: configuration.currentBoardingPointID,
        boardingPoints: points
      ))
      try context.save()
    }
  }
}
