public struct BusRouteLinePoint: Equatable, Hashable, Identifiable, Sendable {
  public var id: Int { sequence }

  public let sequence: Int
  public let x: Double
  public let y: Double

  public init(sequence: Int, x: Double, y: Double) {
    self.sequence = sequence
    self.x = x
    self.y = y
  }
}
