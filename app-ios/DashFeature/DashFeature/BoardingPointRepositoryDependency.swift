import ComposableArchitecture
import DashDomain

extension BoardingPointRepositoryClient: DependencyKey {
  public static let liveValue = Self(
    load: { throw BoardingPointRepositoryError.notConfigured },
    save: { _ in throw BoardingPointRepositoryError.notConfigured }
  )

  public static let testValue = liveValue
}

extension DependencyValues {
  var boardingPointRepository: BoardingPointRepositoryClient {
    get { self[BoardingPointRepositoryClient.self] }
    set { self[BoardingPointRepositoryClient.self] = newValue }
  }
}
