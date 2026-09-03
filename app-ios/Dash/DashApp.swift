import DashData
import DashFeature
import SwiftData
import SwiftUI

@main
struct DashApp: App {
  private let boardingPointRepository: SwiftDataBoardingPointRepository

  init() {
    do {
      let schema = Schema(versionedSchema: DashDataSchemaV1.self)
      let modelContainer = try ModelContainer(
        for: schema,
        migrationPlan: DashDataMigrationPlan.self
      )
      self.boardingPointRepository = SwiftDataBoardingPointRepository(
        modelContainer: modelContainer
      )
    } catch {
      fatalError("Unable to initialize the boarding point data store.")
    }
  }

  var body: some Scene {
    WindowGroup {
      DashFeatureView(
        boardingPointRepository: BoardingPointRepositoryClient(
          load: {
            try await boardingPointRepository.loadConfiguration()
          },
          save: { configuration in
            try await boardingPointRepository.saveConfiguration(configuration)
          }
        ),
        busArrivalRepository: LiveBusArrivalRepository.liveValue,
        busRouteRepository: LiveBusRouteRepository.liveValue,
        busStopRepository: LiveBusStopRepository.liveValue
      )
    }
  }
}
