import ComposableArchitecture
import CoreLocation

public struct UserLocation: Equatable, Sendable {
  public let latitude: Double
  public let longitude: Double

  public init(latitude: Double, longitude: Double) {
    self.latitude = latitude
    self.longitude = longitude
  }
}

public struct UserLocationClient: Sendable {
  public var requestLocation: @Sendable () async throws -> UserLocation

  public init(
    requestLocation: @escaping @Sendable () async throws -> UserLocation
  ) {
    self.requestLocation = requestLocation
  }
}

extension UserLocationClient: DependencyKey {
  public static let liveValue = UserLocationClient {
    let session = CLServiceSession(authorization: .whenInUse)
    defer { session.invalidate() }

    for try await update in CLLocationUpdate.liveUpdates() {
      if update.authorizationDenied
        || update.authorizationDeniedGlobally
        || update.authorizationRestricted
      {
        throw UserLocationError.authorizationDenied
      }

      if update.locationUnavailable {
        throw UserLocationError.locationUnavailable
      }

      if let location = update.location {
        return UserLocation(
          latitude: location.coordinate.latitude,
          longitude: location.coordinate.longitude
        )
      }
    }

    throw UserLocationError.locationUnavailable
  }

  public static let testValue = UserLocationClient {
    throw UserLocationError.locationUnavailable
  }
}

public extension DependencyValues {
  var userLocationClient: UserLocationClient {
    get { self[UserLocationClient.self] }
    set { self[UserLocationClient.self] = newValue }
  }
}

enum UserLocationError: Error, Equatable, Sendable {
  case authorizationDenied
  case locationUnavailable
}
