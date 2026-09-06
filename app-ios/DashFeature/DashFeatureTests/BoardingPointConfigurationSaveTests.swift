import ComposableArchitecture
import Testing

@testable import DashFeature

private enum ConfigurationSaveTestError: Error {
  case failed
}

private actor ConfigurationSaveRecorder {
  private var configurations: [BoardingPointConfiguration] = []
  private var remainingFailureCount: Int

  init(failureCount: Int = 0) {
    self.remainingFailureCount = failureCount
  }

  func save(_ configuration: BoardingPointConfiguration) throws {
    configurations.append(configuration)
    if remainingFailureCount > 0 {
      remainingFailureCount -= 1
      throw ConfigurationSaveTestError.failed
    }
  }

  func savedConfigurations() -> [BoardingPointConfiguration] {
    configurations
  }
}

private actor ControlledConfigurationSaveRecorder {
  private var configurations: [BoardingPointConfiguration] = []
  private var completions: [CheckedContinuation<Void, Never>] = []
  private var saveCountWaiters: [(Int, CheckedContinuation<Void, Never>)] = []

  func save(_ configuration: BoardingPointConfiguration) async {
    configurations.append(configuration)
    let readyWaiters = saveCountWaiters.filter { $0.0 <= configurations.count }
    saveCountWaiters.removeAll { $0.0 <= configurations.count }
    readyWaiters.forEach { $0.1.resume() }
    await withCheckedContinuation { continuation in
      completions.append(continuation)
    }
  }

  func waitUntilSaveCount(_ count: Int) async {
    guard configurations.count < count else { return }
    await withCheckedContinuation { continuation in
      saveCountWaiters.append((count, continuation))
    }
  }

  func completeNextSave() {
    completions.removeFirst().resume()
  }

  func savedConfigurations() -> [BoardingPointConfiguration] {
    configurations
  }
}

@Suite struct BoardingPointConfigurationSaveTests {
  @MainActor
  @Test func updatesAreSavedInOrderWithLatestPendingState() async {
    let recorder = ControlledConfigurationSaveRecorder()
    let firstUpdate = BoardingPoint(
      id: BoardingPoint.suwonStation.id,
      name: "수원역 출근",
      routes: BoardingPoint.suwonStation.routes
    )
    let secondUpdate = BoardingPoint(
      id: BoardingPoint.suwonStation.id,
      name: "수원역 퇴근",
      routes: BoardingPoint.suwonStation.routes
    )
    let firstConfiguration = BoardingPointConfiguration(
      boardingPoints: [firstUpdate],
      currentBoardingPointID: nil
    )
    let secondConfiguration = BoardingPointConfiguration(
      boardingPoints: [secondUpdate],
      currentBoardingPointID: nil
    )
    var initialState = CurrentBoardingPointFeature.State()
    initialState.boardingPoints = [.suwonStation]

    let store = TestStore(initialState: initialState) {
      CurrentBoardingPointFeature()
    } withDependencies: {
      $0.boardingPointRepository = BoardingPointRepositoryClient(
        load: { BoardingPointConfiguration(boardingPoints: [], currentBoardingPointID: nil) },
        save: { await recorder.save($0) }
      )
    }

    await store.send(.boardingPointUpdated(firstUpdate)) {
      $0.boardingPoints = [firstUpdate]
      $0.configurationSaveInFlight = firstConfiguration
    }
    await recorder.waitUntilSaveCount(1)
    await store.send(.boardingPointUpdated(secondUpdate)) {
      $0.boardingPoints = [secondUpdate]
      $0.pendingConfigurationSave = secondConfiguration
    }
    await recorder.completeNextSave()
    await store.receive(.configurationSaveResponse(.success)) {
      $0.configurationSaveInFlight = secondConfiguration
      $0.pendingConfigurationSave = nil
    }
    await recorder.waitUntilSaveCount(2)
    await recorder.completeNextSave()
    await store.receive(.configurationSaveResponse(.success)) {
      $0.configurationSaveInFlight = nil
    }

    #expect(await recorder.savedConfigurations() == [firstConfiguration, secondConfiguration])
  }

  @MainActor
  @Test func failedSaveCanRetryLatestState() async {
    let recorder = ConfigurationSaveRecorder(failureCount: 1)
    let updatedBoardingPoint = BoardingPoint(
      id: BoardingPoint.suwonStation.id,
      name: "수원역 출근",
      routes: BoardingPoint.suwonStation.routes
    )
    let configuration = BoardingPointConfiguration(
      boardingPoints: [updatedBoardingPoint],
      currentBoardingPointID: nil
    )
    var initialState = CurrentBoardingPointFeature.State()
    initialState.boardingPoints = [.suwonStation]

    let store = TestStore(initialState: initialState) {
      CurrentBoardingPointFeature()
    } withDependencies: {
      $0.boardingPointRepository = BoardingPointRepositoryClient(
        load: { BoardingPointConfiguration(boardingPoints: [], currentBoardingPointID: nil) },
        save: { try await recorder.save($0) }
      )
    }

    await store.send(.boardingPointUpdated(updatedBoardingPoint)) {
      $0.boardingPoints = [updatedBoardingPoint]
      $0.configurationSaveInFlight = configuration
    }
    await store.receive(.configurationSaveResponse(.failure)) {
      $0.configurationSaveErrorMessage = "변경사항을 저장하지 못했습니다. 다시 시도해주세요."
      $0.configurationSaveInFlight = nil
      $0.pendingConfigurationSave = configuration
    }
    await store.send(.retryConfigurationSaveButtonTapped) {
      $0.configurationSaveErrorMessage = nil
      $0.configurationSaveInFlight = configuration
      $0.pendingConfigurationSave = nil
    }
    await store.receive(.configurationSaveResponse(.success)) {
      $0.configurationSaveInFlight = nil
    }

    #expect(await recorder.savedConfigurations() == [configuration, configuration])
  }

  @MainActor
  @Test func insertionSavesNewBoardingPoint() async {
    let recorder = ConfigurationSaveRecorder()
    let newBoardingPoint = BoardingPoint(
      id: "new-boarding-point",
      name: "새 탑승 지점",
      routes: [.theHyundaiSeoul: [.route662]]
    )
    let configuration = BoardingPointConfiguration(
      boardingPoints: [.suwonStation, newBoardingPoint],
      currentBoardingPointID: nil
    )
    var initialState = CurrentBoardingPointFeature.State()
    initialState.boardingPoints = [.suwonStation]

    let store = TestStore(initialState: initialState) {
      CurrentBoardingPointFeature()
    } withDependencies: {
      $0.boardingPointRepository = BoardingPointRepositoryClient(
        load: { BoardingPointConfiguration(boardingPoints: [], currentBoardingPointID: nil) },
        save: { try await recorder.save($0) }
      )
    }

    await store.send(.boardingPointUpdated(newBoardingPoint)) {
      $0.boardingPoints = [.suwonStation, newBoardingPoint]
      $0.configurationSaveInFlight = configuration
    }
    await store.receive(.configurationSaveResponse(.success)) {
      $0.configurationSaveInFlight = nil
    }

    #expect(await recorder.savedConfigurations() == [configuration])
  }

  @MainActor
  @Test func deletionSavesRemainingConfiguration() async {
    let recorder = ConfigurationSaveRecorder()
    let configuration = BoardingPointConfiguration(
      boardingPoints: [.suwonStation],
      currentBoardingPointID: BoardingPoint.suwonStation.id
    )
    var initialState = CurrentBoardingPointFeature.State()
    initialState.boardingPoints = [.suwonStation, .theHyundaiSeoul]
    initialState.boardingPointSelection = .selected(BoardingPoint.suwonStation.id)

    let store = TestStore(initialState: initialState) {
      CurrentBoardingPointFeature()
    } withDependencies: {
      $0.boardingPointRepository = BoardingPointRepositoryClient(
        load: { BoardingPointConfiguration(boardingPoints: [], currentBoardingPointID: nil) },
        save: { try await recorder.save($0) }
      )
    }

    await store.send(.boardingPointDeleted(BoardingPoint.theHyundaiSeoul.id)) {
      $0.boardingPoints = [.suwonStation]
      $0.configurationSaveInFlight = configuration
    }
    await store.receive(.configurationSaveResponse(.success)) {
      $0.configurationSaveInFlight = nil
    }

    #expect(await recorder.savedConfigurations() == [configuration])
  }
}
