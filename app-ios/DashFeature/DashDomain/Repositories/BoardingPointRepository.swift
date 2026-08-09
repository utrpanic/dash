public struct BoardingPointConfiguration: Equatable, Sendable {
  public let boardingPoints: [BoardingPoint]
  public let currentBoardingPointID: BoardingPoint.ID?

  public init(
    boardingPoints: [BoardingPoint],
    currentBoardingPointID: BoardingPoint.ID?
  ) {
    self.boardingPoints = boardingPoints
    self.currentBoardingPointID = currentBoardingPointID
  }
}

public protocol BoardingPointRepository: Sendable {
  func loadConfiguration() async throws -> BoardingPointConfiguration
  func saveConfiguration(_ configuration: BoardingPointConfiguration) async throws
}

public struct BoardingPointRepositoryClient: BoardingPointRepository, Sendable {
  public var load: @Sendable () async throws -> BoardingPointConfiguration
  public var save: @Sendable (BoardingPointConfiguration) async throws -> Void

  public init(
    load: @escaping @Sendable () async throws -> BoardingPointConfiguration,
    save: @escaping @Sendable (BoardingPointConfiguration) async throws -> Void
  ) {
    self.load = load
    self.save = save
  }

  public func loadConfiguration() async throws -> BoardingPointConfiguration {
    try await load()
  }

  public func saveConfiguration(_ configuration: BoardingPointConfiguration) async throws {
    try await save(configuration)
  }
}

public enum BoardingPointRepositoryError: Error, Equatable, Sendable {
  case notConfigured
}
