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
