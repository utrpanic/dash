import DashDomain
import Foundation
import SwiftData

enum BusStopPersistenceError: Error, Equatable {
  case invalidIdentity(String)
  case ambiguousLegacyIdentity(String)
}

public enum DashDataMigrationPlan: SchemaMigrationPlan {
  public static let schemas: [any VersionedSchema.Type] = [
    DashDataSchemaV1.self,
    DashDataSchemaV2.self,
  ]

  public static let stages: [MigrationStage] = [
    .custom(
      fromVersion: DashDataSchemaV1.self,
      toVersion: DashDataSchemaV2.self,
      willMigrate: nil,
      didMigrate: { context in
        let stops = try context.fetch(
          FetchDescriptor<DashDataSchemaV2.BoardingPointStopRecord>()
        )
        for stop in stops {
          switch try legacyIdentity(for: stop) {
          case .gyeonggi:
            stop.region = "gyeonggi"
            stop.arsID = nil
          case let .seoul(_, arsID):
            stop.region = "seoul"
            stop.arsID = arsID
          }
        }
        try context.save()
      }
    ),
  ]

  // V1 stored full identity in the record key after the typed stop-ID change.
  // Read the suffix so hyphens in the boarding point ID do not affect recovery.
  private static func legacyIdentity(
    for stop: DashDataSchemaV2.BoardingPointStopRecord
  ) throws -> BusStop.ID {
    if stop.id.hasSuffix("-gyeonggi-\(stop.busStopID)") {
      return .gyeonggi(stopID: stop.busStopID)
    }
    if let range = stop.id.range(of: "-seoul-\(stop.busStopID)-", options: .backwards) {
      let arsID = String(stop.id[range.upperBound...])
      if arsID.allSatisfy({ $0.isASCII && $0.isNumber }) {
        return .seoul(stopID: stop.busStopID, arsID: arsID)
      }
    }

    // Earlier V1 keys contain only the numeric stop ID; ARS was not stored.
    if let knownStop = BusStop.allKnown.first(where: { $0.id.stopID == stop.busStopID }) {
      return knownStop.id
    }
    let regions = Set(stop.selectedRoutes.map(\.region))
    if regions == ["gyeonggi"] {
      return .gyeonggi(stopID: stop.busStopID)
    }
    if regions == ["seoul"] {
      // Empty ARS is an existing domain representation for unavailable ARS data.
      return .seoul(stopID: stop.busStopID, arsID: "")
    }
    throw BusStopPersistenceError.ambiguousLegacyIdentity(stop.id)
  }
}
