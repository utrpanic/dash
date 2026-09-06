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

    let updated = configuration(stops: [
      stop(.seoul(stopID: 999000003, arsID: "00456")),
    ])
    try await save(updated, to: url)
    #expect(try await load(from: url) == updated)
  }

  @Test func initializesFreshStore() async throws {
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

  private func container(at url: URL) throws -> ModelContainer {
    let schema = Schema(versionedSchema: DashDataSchemaV1.self)
    return try ModelContainer(
      for: schema,
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
    BusStop(
      id: id,
      name: "검색한 정류장",
      alias: "출근",
      latitude: 37.5,
      longitude: 127.0
    )
  }

  private func configuration(stops: [BusStop]) -> BoardingPointConfiguration {
    let point = BoardingPoint(
      id: "commute-point",
      name: "출근",
      routes: Dictionary(uniqueKeysWithValues: stops.enumerated().map { index, stop in
        (stop, index == 1 ? Set([BusRoute.route13]) : Set())
      })
    )
    return BoardingPointConfiguration(
      boardingPoints: [point],
      currentBoardingPointID: point.id
    )
  }
}
